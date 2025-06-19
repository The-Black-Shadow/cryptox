import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/models/transaction_record_model.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:flutter/material.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<TransactionRecordModel>> fetchRecentTransactions({
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionRecordModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching recent transactions: $e");
      throw Exception("Could not load recent transactions.");
    }
  }

  Future<TransactionRecordModel?> traceTransactionById(
    String transactionId,
  ) async {
    try {
      final docSnapshot = await _firestore
          .collection('transactions')
          .doc(transactionId.trim())
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return TransactionRecordModel.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("Error tracing transaction by ID: $e");
      throw Exception("Could not find transaction.");
    }
  }

  Future<TransactionRecordModel?> findTransactionByInputParcel(
    String parcelId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('inputParcelIds', arrayContains: parcelId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TransactionRecordModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print("Error finding transaction by input parcel: $e");
      throw Exception("Could not trace parcel forward.");
    }
  }
  /// Finds a user by their email to get their ID and profile.
  Future<UserModel?> findUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('user_email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final user = UserModel.fromJson(query.docs.first.data());
        return user;
      }
      return null;
    } catch (e) {
      debugPrint("Error finding user by email: $e");
      throw Exception("Could not find user.");
    }
  }

  /// Fetches all active digital notes for a specific user ID.
  Future<List<DigitalNoteModel>> fetchUserDigitalNotes(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('digital_notes')
          .where('ownerUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('denomination', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => DigitalNoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching user's digital notes: $e");
      throw Exception("Could not load user's notes.");
    }
  }
  
  /// Creates new digital notes for a user based on a deposit amount.
  Future<void> depositDigitalNotes({
    required String userId,
    required double totalAmount,
    required String adminId,
    required String adminEmail,
  }) async {
    if (totalAmount <= 0) throw Exception("Deposit amount must be positive.");

    final notesToCreate = _calculateNoteDistribution(totalAmount);
    if (notesToCreate.isEmpty) throw Exception("Cannot create notes for this amount.");

    final WriteBatch batch = _firestore.batch();
    final depositTransactionId = 'DEP_${DateTime.now().millisecondsSinceEpoch}';

    for (var note in notesToCreate) {
      final noteRef = _firestore.collection('digital_notes').doc();
      final serialNumber = 'HC ${noteRef.id}'.toUpperCase();
      
      final newNote = DigitalNoteModel(
        noteId: noteRef.id,
        serialNumber: serialNumber,
        // --- THIS IS THE FIX for Error 1 ---
        // Asserting that 'denomination' is not null, as our logic guarantees it.
        denomination: note['denomination']!,
        ownerUserId: userId,
        status: 'active',
        originatorInfo: {
          'adminId': adminId,
          'adminEmail': adminEmail,
          'depositTransactionId': depositTransactionId,
          'createdAt': Timestamp.now(),
        },
        history: [
          {
            'fromUserId': 'deposit_system',
            'toUserId': userId,
            'timestamp': Timestamp.now(),
            'transactionId': depositTransactionId,
          }
        ],
      );
      // --- THIS IS THE FIX for Error 2 ---
      // This call now works because we added the toJson() method.
      batch.set(noteRef, newNote.toJson());
    }

    await batch.commit();
  }

  /// Helper method to calculate note distribution using a greedy algorithm.
  List<Map<String, double>> _calculateNoteDistribution(double amount) {
    final List<double> denominations = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    final List<Map<String, double>> notes = [];
    double remainingAmount = amount;

    for (var den in denominations) {
      if (remainingAmount >= den) {
        int count = (remainingAmount / den).floor();
        for (int i = 0; i < count; i++) {
          notes.add({'denomination': den});
        }
        remainingAmount -= count * den;
      }
    }
    return notes;
  }
}

