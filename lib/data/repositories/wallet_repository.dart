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

  /// Watches both simple balances and Tether parcels, combining them into a single real-time stream.
  Stream<CryptoBalance> watchCurrentUserCryptoBalance() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.error(Exception('User not logged in.'));
    }

    // Stream 1: For simple, non-traceable balances (BTC, ETH, etc.)
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

    // Stream 2: For traceable Tether (USDT) balance, calculated from parcels
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

    // Combine the two streams using rxdart to create a single CryptoBalance object
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
    if (currentUser.email == recipientEmail)
      throw Exception('You cannot send crypto to yourself.');
    if (amountToSend <= 0) throw Exception('Amount must be positive.');

    final recipientQuery = await _firestore
        .collection('users')
        .where('user_email', isEqualTo: recipientEmail)
        .limit(1)
        .get();
    if (recipientQuery.docs.isEmpty)
      throw Exception('Recipient user not found.');
    final recipientId = recipientQuery.docs.first.id;
    final recipientUser = UserModel.fromJson(recipientQuery.docs.first.data());

    const String coinType = 'tether';
    final senderParcelsRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('${coinType}_parcels');
    final recipientParcelsRef = _firestore
        .collection('users')
        .doc(recipientId)
        .collection('${coinType}_parcels');
    final transactionLedgerRef = _firestore.collection('transactions').doc();

    final senderParcelQuery = await senderParcelsRef
        .orderBy('receivedAt', descending: true)
        .get();

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
          throw Exception(
            "Transaction failed. One of your coin parcels was spent. Please try again.",
          );
        }
      }

      final List<ParcelModel> parcelsToSpendModels = docsToSpend
          .map((doc) => ParcelModel.fromFirestore(doc))
          .toList();
      final List<Map<String, dynamic>> inputsForLedger = [];
      final List<Map<String, dynamic>> outputsForLedger = [];

      for (var parcel in parcelsToSpendModels) {
        transaction.delete(senderParcelsRef.doc(parcel.parcelId));
        inputsForLedger.add({
          'ownerId': currentUser.uid,
          'parcelId': parcel.parcelId,
          'amount': parcel.amount,
        });
      }

      final recipientParcelRef = recipientParcelsRef.doc();
      transaction.set(
        recipientParcelRef,
        ParcelModel(
          parcelId: recipientParcelRef.id,
          amount: amountToSend,
          receivedFromUserId: currentUser.uid,
          originTransactionId: transactionLedgerRef.id,
          receivedAt: Timestamp.now(),
        ).toJson(),
      );
      outputsForLedger.add({
        'recipientUserId': recipientId,
        'newParcelId': recipientParcelRef.id,
        'amount': amountToSend,
      });

      final double changeAmount = collectedAmount - amountToSend;
      if (changeAmount > 0.000001) {
        final changeParcelRef = senderParcelsRef.doc();
        transaction.set(
          changeParcelRef,
          ParcelModel(
            parcelId: changeParcelRef.id,
            amount: changeAmount,
            receivedFromUserId: currentUser.uid,
            originTransactionId: transactionLedgerRef.id,
            receivedAt: Timestamp.now(),
          ).toJson(),
        );
        outputsForLedger.add({
          'recipientUserId': currentUser.uid,
          'newParcelId': changeParcelRef.id,
          'amount': changeAmount,
        });
      }

      // --- THIS IS THE FIX ---
      final newTransactionRecord = TransactionRecordModel(
        transactionId: transactionLedgerRef.id,
        status: 'completed',
        transactionType: 'send', // Added the missing required parameter
        timestamp: Timestamp.now(),
        coinType: coinType,
        totalAmount: amountToSend,
        fromUserId: currentUser.uid,
        fromUserEmail: currentUser.email ?? 'N/A',
        toUserId: recipientId,
        toUserEmail: recipientUser.userEmail,
        inputParcelIds: inputsForLedger
            .map((input) => input['parcelId'] as String)
            .toList(),
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

  /// Converts a simple balance coin (like BTC) into traceable Tether parcels.
  Future<void> convertToTether({
    required String fromCoinKey,
    required double fromAmount,
    required double tetherToReceive,
  }) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not logged in.');

    final balanceDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cryptoBalance')
        .doc('balance');
    final tetherParcelRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tether_parcels')
        .doc();
    final transactionLedgerRef = _firestore.collection('transactions').doc();

    return _firestore.runTransaction((transaction) async {
      final balanceDoc = await transaction.get(balanceDocRef);
      if (!balanceDoc.exists || balanceDoc.data() == null)
        throw Exception("Balance document not found.");

      final balances = CryptoBalance.fromJson(balanceDoc.data()!);
      double getBalance(String key) {
        switch (key) {
          case 'bitcoin':
            return balances.bitcoin;
          case 'ethereum':
            return balances.ethereum;
          case 'bnb':
            return balances.bnb;
          case 'x':
            return balances.x;
          default:
            return 0.0;
        }
      }

      final currentFromBalance = getBalance(fromCoinKey);
      if (currentFromBalance < fromAmount)
        throw Exception("Insufficient $fromCoinKey balance.");

      transaction.update(balanceDocRef, {
        fromCoinKey: FieldValue.increment(-fromAmount),
      });

      final newParcel = ParcelModel(
        parcelId: tetherParcelRef.id,
        amount: tetherToReceive,
        receivedFromUserId: user.uid,
        originTransactionId: transactionLedgerRef.id,
        receivedAt: Timestamp.now(),
      );
      transaction.set(tetherParcelRef, newParcel.toJson());

      final newRecord = TransactionRecordModel(
        transactionId: transactionLedgerRef.id,
        status: 'completed',
        transactionType: 'convert_in',
        timestamp: Timestamp.now(),
        coinType: 'tether',
        totalAmount: tetherToReceive,
        fromUserId: user.uid,
        fromUserEmail: user.email ?? '',
        toUserId: user.uid,
        toUserEmail: user.email ?? '',
        inputParcelIds: [],
        inputs: [
          {'type': 'simple_balance', 'coin': fromCoinKey, 'amount': fromAmount},
        ],
        outputs: [
          {
            'recipientUserId': user.uid,
            'newParcelId': newParcel.parcelId,
            'amount': tetherToReceive,
          },
        ],
      );
      transaction.set(transactionLedgerRef, newRecord.toJson());
    });
  }

  /// Consumes traceable Tether parcels and converts them into a simple balance coin.
  Future<void> convertFromTether({
    required double tetherAmountToSpend,
    required String toCoinKey,
    required double toCoinAmountToReceive,
  }) async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) throw Exception('User not logged in.');

    final senderParcelsRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tether_parcels');
    final balanceDocRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('cryptoBalance')
        .doc('balance');
    final transactionLedgerRef = _firestore.collection('transactions').doc();

    final senderParcelQuery = await senderParcelsRef
        .orderBy('receivedAt', descending: true)
        .get();

    final List<DocumentSnapshot> docsToSpend = [];
    double collectedAmount = 0;
    for (var doc in senderParcelQuery.docs) {
      if (collectedAmount < tetherAmountToSpend) {
        docsToSpend.add(doc);
        collectedAmount += (doc.data())['amount'];
      } else {
        break;
      }
    }

    if (collectedAmount < tetherAmountToSpend)
      throw Exception("Insufficient Tether balance.");

    return _firestore.runTransaction((transaction) async {
      for (var docSnapshot in docsToSpend) {
        final freshDoc = await transaction.get(docSnapshot.reference);
        if (!freshDoc.exists)
          throw Exception(
            "Transaction failed. A parcel was spent. Please try again.",
          );
      }

      final List<ParcelModel> parcelsToSpendModels = docsToSpend
          .map((doc) => ParcelModel.fromFirestore(doc))
          .toList();
      final List<Map<String, dynamic>> inputsForLedger = [];

      for (var parcel in parcelsToSpendModels) {
        transaction.delete(senderParcelsRef.doc(parcel.parcelId));
        inputsForLedger.add({
          'ownerId': currentUser.uid,
          'parcelId': parcel.parcelId,
          'amount': parcel.amount,
        });
      }

      final double changeAmount = collectedAmount - tetherAmountToSpend;
      if (changeAmount > 0.000001) {
        final changeParcelRef = senderParcelsRef.doc();
        transaction.set(
          changeParcelRef,
          ParcelModel(
            parcelId: changeParcelRef.id,
            amount: changeAmount,
            receivedFromUserId: currentUser.uid,
            originTransactionId: transactionLedgerRef.id,
            receivedAt: Timestamp.now(),
          ).toJson(),
        );
      }

      transaction.update(balanceDocRef, {
        toCoinKey: FieldValue.increment(toCoinAmountToReceive),
      });

      final newRecord = TransactionRecordModel(
        transactionId: transactionLedgerRef.id,
        status: 'completed',
        transactionType: 'convert_out',
        timestamp: Timestamp.now(),
        coinType: toCoinKey,
        totalAmount: toCoinAmountToReceive,
        fromUserId: currentUser.uid,
        fromUserEmail: currentUser.email ?? '',
        toUserId: currentUser.uid,
        toUserEmail: currentUser.email ?? '',
        inputParcelIds: inputsForLedger
            .map((input) => input['parcelId'] as String)
            .toList(),
        inputs: inputsForLedger,
        outputs: [
          {
            'recipientUserId': currentUser.uid,
            'type': 'simple_balance',
            'coin': toCoinKey,
            'amount': toCoinAmountToReceive,
          },
        ],
      );
      transaction.set(transactionLedgerRef, newRecord.toJson());
    });
  }

  /// Fetches all transactions for the current user (both sent and received).
  Future<List<TransactionRecordModel>> fetchUserTransactions({
    int? limit,
  }) async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    try {
      Query sentQueryBase = _firestore
          .collection('transactions')
          .where('fromUserId', isEqualTo: currentUser.uid);
      Query receivedQueryBase = _firestore
          .collection('transactions')
          .where('toUserId', isEqualTo: currentUser.uid);

      if (limit != null) {
        sentQueryBase = sentQueryBase.limit(limit);
        receivedQueryBase = receivedQueryBase.limit(limit);
      }

      final List<QuerySnapshot> results = await Future.wait([
        sentQueryBase.get(),
        receivedQueryBase.get(),
      ]);
      final allDocs = [...results[0].docs, ...results[1].docs];

      final uniqueDocs = <String, DocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      final transactions = uniqueDocs.values
          .map(
            (doc) => TransactionRecordModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (limit != null && transactions.length > limit) {
        return transactions.sublist(0, limit);
      }

      return transactions;
    } catch (e) {
      debugPrint("Error fetching user transactions: $e");
      throw Exception("Could not load transaction history.");
    }
  }
}
