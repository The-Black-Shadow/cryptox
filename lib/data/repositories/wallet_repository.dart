import 'dart:async'; // Required for Stream
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/crypto_balance_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  WalletRepository({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // Old method (fetches once) - keep it for other purposes if needed
  Future<CryptoBalance> getCurrentUserCryptoBalanceFuture() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in. Unable to fetch balance.');
    }
    // ... ( existing get() logic) ...
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cryptoBalance')
          .doc('balance')
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return CryptoBalance.fromJson(docSnapshot.data()!);
      } else {
        return const CryptoBalance(
          bitcoin: 0.0,
          ethereum: 0.0,
          bnb: 0.0,
          x: 0.0,
        );
      }
    } catch (e) {
      debugPrint('Error fetching crypto balance: $e');
      throw Exception('Failed to fetch crypto balance: $e');
    }
  }

  // New method to stream balance updates
  Stream<CryptoBalance> watchCurrentUserCryptoBalance() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      // Return a stream that emits an error or an empty/default balance
      return Stream.error(
        Exception('User not logged in. Unable to watch balance.'),
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cryptoBalance')
        .doc('balance')
        .snapshots() // This returns a Stream<DocumentSnapshot>
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return CryptoBalance.fromJson(snapshot.data()!);
          } else {
            // If the document doesn't exist, emit a default balance
            return const CryptoBalance(
              bitcoin: 0.0,
              ethereum: 0.0,
              bnb: 0.0,
              x: 0.0,
            );
          }
        })
        .handleError((error) {
          debugPrint('Error in balance stream: $error');
          throw Exception('Failed to listen to balance updates: $error');
        });
  }

  Future<void> performConversionTransaction({
    required String userId,
    required String fromCoinFirestoreKey,
    required double amountToDecrement,
    required String toCoinFirestoreKey,
    required double amountToIncrement,
  }) async {
    final userBalanceRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cryptoBalance')
        .doc('balance');

    return _firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(userBalanceRef);

          if (!snapshot.exists || snapshot.data() == null) {
            throw Exception("User balance document does not exist.");
          }

          final currentBalances = CryptoBalance.fromJson(snapshot.data()!);
          double currentFromBalance = 0;
          double currentToBalance = 0;

          // Helper to get balance by key from CryptoBalance object
          double getBalance(CryptoBalance balance, String key) {
            switch (key) {
              case 'bitcoin':
                return balance.bitcoin;
              case 'ethereum':
                return balance.ethereum;
              case 'bnb':
                return balance.bnb;
              case 'x':
                return balance.x;
              default:
                throw Exception("Invalid fromCoinFirestoreKey: $key");
            }
          }

          currentFromBalance = getBalance(
            currentBalances,
            fromCoinFirestoreKey,
          );
          currentToBalance = getBalance(currentBalances, toCoinFirestoreKey);

          if (currentFromBalance < amountToDecrement) {
            throw Exception("Insufficient balance for $fromCoinFirestoreKey.");
          }

          final Map<String, dynamic> updates = {};
          updates[fromCoinFirestoreKey] =
              currentFromBalance - amountToDecrement;
          updates[toCoinFirestoreKey] = currentToBalance + amountToIncrement;

          transaction.update(userBalanceRef, updates);
        })
        .catchError((error) {
          debugPrint("Conversion transaction failed: $error");
          throw Exception("Conversion failed: ${error.toString()}");
        });
  }
}
