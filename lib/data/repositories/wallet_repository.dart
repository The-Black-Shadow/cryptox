import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/crypto_balance_model.dart';
import 'package:cryptox/data/models/percel_model.dart';
import 'package:cryptox/data/models/transaction_record_model.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  WalletRepository({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Fetches all transactions for the current user (both sent and received).
  Future<List<TransactionRecordModel>> fetchUserTransactions() async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    try {
      // Query for transactions where the user was the sender
      final sentQuery = _firestore
          .collection('transactions')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .get();

      // Query for transactions where the user was the recipient
      final receivedQuery = _firestore
          .collection('transactions')
          .where('toUserId', isEqualTo: currentUser.uid)
          .get();

      // Wait for both queries to complete
      final List<QuerySnapshot> results = await Future.wait([
        sentQuery,
        receivedQuery,
      ]);

      // Combine the documents from both queries
      final allDocs = [...results[0].docs, ...results[1].docs];

      // Use a map to handle potential duplicates (if a user sends to themselves, though disallowed)
      final uniqueDocs = <String, DocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      // Convert the documents to TransactionRecordModel objects
      final transactions = uniqueDocs.values
          .map(
            (doc) => TransactionRecordModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      // Sort the combined list by timestamp, newest first
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return transactions;
    } catch (e) {
      debugPrint("Error fetching user transactions: $e");
      throw Exception("Could not load transaction history.");
    }
  }

  Stream<CryptoBalance> watchCurrentUserCryptoBalance() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.error(Exception('User not logged in.'));
    }

    final simpleBalanceStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cryptoBalance')
        .doc('balance')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return snapshot.data()!;
          }
          return <String, dynamic>{};
        });

    final tetherParcelsStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tether_parcels')
        .snapshots()
        .map((snapshot) {
          double totalTether = 0.0;
          for (var doc in snapshot.docs) {
            totalTether += (doc.data()['amount'] as num? ?? 0).toDouble();
          }
          return totalTether;
        });

    return Rx.combineLatest2(simpleBalanceStream, tetherParcelsStream, (
      Map<String, dynamic> simpleBalances,
      double tetherBalance,
    ) {
      return CryptoBalance(
        bitcoin: (simpleBalances['bitcoin'] as num? ?? 0).toDouble(),
        ethereum: (simpleBalances['ethereum'] as num? ?? 0).toDouble(),
        bnb: (simpleBalances['bnb'] as num? ?? 0).toDouble(),
        x: (simpleBalances['x'] as num? ?? 0).toDouble(),
        tether: tetherBalance,
      );
    }).handleError((error) {
      debugPrint("Error in combined balance stream: $error");
      return const CryptoBalance(
        bitcoin: 0,
        ethereum: 0,
        bnb: 0,
        x: 0,
        tether: 0,
      );
    });
  }

  /// Sends USDT using the Parcel model (UTXO-like) with LIFO logic.
  Future<void> sendTether({
    required String recipientEmail,
    required double amountToSend,
  }) async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) throw Exception('User not logged in.');
    if (currentUser.email == recipientEmail) throw Exception('You cannot send crypto to yourself.');
    if (amountToSend <= 0) throw Exception('Amount must be positive.');

    final recipientQuery = await _firestore.collection('users').where('user_email', isEqualTo: recipientEmail).limit(1).get();
    if (recipientQuery.docs.isEmpty) throw Exception('Recipient user not found.');
    final recipientId = recipientQuery.docs.first.id;
    final recipientUser = UserModel.fromJson(recipientQuery.docs.first.data());

    const String coinType = 'tether';
    final senderParcelsRef = _firestore.collection('users').doc(currentUser.uid).collection('${coinType}_parcels');
    final recipientParcelsRef = _firestore.collection('users').doc(recipientId).collection('${coinType}_parcels');
    final transactionLedgerRef = _firestore.collection('transactions').doc();

    final senderParcelQuery = await senderParcelsRef.orderBy('receivedAt', descending: true).get();

    final List<DocumentSnapshot> docsToSpend = [];
    double collectedAmount = 0;
    for (var doc in senderParcelQuery.docs) {
      if (collectedAmount < amountToSend) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['amount'] != null) {
          docsToSpend.add(doc);
          collectedAmount += (data['amount'] as num).toDouble();
        }
      } else {
        break;
      }
    }

    if (collectedAmount < amountToSend) {
      throw Exception("Insufficient Tether balance.");
    }

    return _firestore.runTransaction((transaction) async {
      for (var docSnapshot in docsToSpend) {
        final freshDoc = await transaction.get(docSnapshot.reference);
        if (!freshDoc.exists) {
          throw Exception("Transaction failed. One of your coin parcels was spent. Please try again.");
        }
      }

      final List<ParcelModel> parcelsToSpendModels = docsToSpend.map((doc) => ParcelModel.fromFirestore(doc)).toList();
      final List<Map<String, dynamic>> inputsForLedger = [];
      final List<Map<String, dynamic>> outputsForLedger = [];

      for (var parcel in parcelsToSpendModels) {
        transaction.delete(senderParcelsRef.doc(parcel.parcelId));
        inputsForLedger.add({'ownerId': currentUser.uid, 'parcelId': parcel.parcelId, 'amount': parcel.amount});
      }

      final recipientParcelRef = recipientParcelsRef.doc();
      transaction.set(recipientParcelRef, ParcelModel(
        parcelId: recipientParcelRef.id,
        amount: amountToSend,
        receivedFromUserId: currentUser.uid,
        originTransactionId: transactionLedgerRef.id,
        receivedAt: Timestamp.now(),
      ).toJson());
      outputsForLedger.add({'recipientUserId': recipientId, 'newParcelId': recipientParcelRef.id, 'amount': amountToSend});

      final double changeAmount = collectedAmount - amountToSend;
      if (changeAmount > 0.000001) {
        final changeParcelRef = senderParcelsRef.doc();
        transaction.set(changeParcelRef, ParcelModel(
          parcelId: changeParcelRef.id,
          amount: changeAmount,
          receivedFromUserId: currentUser.uid,
          originTransactionId: transactionLedgerRef.id,
          receivedAt: Timestamp.now(),
        ).toJson());
        outputsForLedger.add({'recipientUserId': currentUser.uid, 'newParcelId': changeParcelRef.id, 'amount': changeAmount});
      }

      final newTransactionRecord = TransactionRecordModel(
        transactionId: transactionLedgerRef.id,
        status: 'completed',
        timestamp: Timestamp.now(),
        coinType: coinType,
        totalAmount: amountToSend,
        fromUserId: currentUser.uid,
        fromUserEmail: currentUser.email ?? 'N/A',
        toUserId: recipientId,
        toUserEmail: recipientUser.userEmail,
        inputParcelIds: inputsForLedger.map((input) => input['parcelId'] as String).toList(),
        inputs: inputsForLedger,
        outputs: outputsForLedger,
      );
      transaction.set(transactionLedgerRef, newTransactionRecord.toJson());
    });
  }


  /// Adds deposited funds as a new Tether parcel for the current user.
  Future<void> addTetherAsParcel({required double amountToAdd}) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not logged in.');

    const String coinType = 'tether';
    final parcelsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('${coinType}_parcels');
    final newParcelRef = parcelsRef.doc();

    final newParcel = ParcelModel(
      parcelId: newParcelRef.id,
      amount: amountToAdd,
      receivedFromUserId: 'deposit_system',
      originTransactionId: 'deposit_${DateTime.now().millisecondsSinceEpoch}',
      receivedAt: Timestamp.now(),
    );
    await newParcelRef.set(newParcel.toJson());
  }
}
