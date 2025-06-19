import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/models/transaction_record_model.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint("Error fetching recent transactions: $e");
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
      debugPrint("Error finding transaction by input parcel: $e");
      throw Exception("Could not trace parcel forward.");
    }
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('user_email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final user = UserModel.fromJson(doc.data());
        return {'id': doc.id, 'user': user};
      }
      return null;
    } catch (e) {
      debugPrint("Error finding user by email: $e");
      throw Exception("Could not find user.");
    }
  }

  /// Fetches all of a user's notes that are NOT spent (i.e., 'active' or 'blocked').
  Future<List<DigitalNoteModel>> fetchUserDigitalNotes(String userId) async {
    try {
      // --- THIS IS THE FIX ---
      // The `whereIn` operator allows us to fetch documents where the 'status'
      // field is either 'active' OR 'blocked', effectively excluding 'spent' notes.
      final querySnapshot = await _firestore
          .collection('digital_notes')
          .where('ownerUserId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'blocked'])
          .orderBy('denomination', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DigitalNoteModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Error fetching user's digital notes: $e");
      throw Exception("Could not load user's notes.");
    }
  }

  Future<void> updateNoteStatus(String noteId, String newStatus) async {
    if (noteId.isEmpty || (newStatus != 'active' && newStatus != 'blocked')) {
      throw Exception("Invalid input for updating note status.");
    }
    try {
      await _firestore.collection('digital_notes').doc(noteId).update({
        'status': newStatus,
      });
    } catch (e) {
      throw Exception("Failed to update note status.");
    }
  }

  Future<void> depositDigitalNotes({
    required String userId,
    required double totalAmount,
    required String adminId,
    required String adminEmail,
  }) async {
    if (totalAmount <= 0) throw Exception("Deposit amount must be positive.");

    final notesToCreate = _calculateNoteDistribution(totalAmount);
    if (notesToCreate.isEmpty)
      throw Exception("Cannot create notes for this amount.");

    final WriteBatch batch = _firestore.batch();
    final depositTransactionId = 'DEP_${DateTime.now().millisecondsSinceEpoch}';

    for (var note in notesToCreate) {
      final noteRef = _firestore.collection('digital_notes').doc();
      final serialNumber = 'HC ${noteRef.id}'.toUpperCase();

      final newNote = DigitalNoteModel(
        noteId: noteRef.id,
        serialNumber: serialNumber,
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
          },
        ],
      );
      batch.set(noteRef, newNote.toJson());
    }

    await batch.commit();
  }

  Future<int> blockNotesByTransaction(String transactionId) async {
    if (transactionId.trim().isEmpty) {
      throw Exception("Transaction ID cannot be empty.");
    }

    final notesCollection = _firestore.collection('digital_notes');

    // First, find the transaction record to get the list of created notes.
    final txDoc = await _firestore
        .collection('digital_note_transactions')
        .doc(transactionId)
        .get();

    List<String> createdNoteSerials = [];
    if (txDoc.exists && txDoc.data()!.containsKey('createdNoteIds')) {
      createdNoteSerials = List<String>.from(
        txDoc.data()!['createdNoteIds'] ?? [],
      );
    } else {
      // Fallback for deposit transactions which might not have a separate ledger entry
      final depositQuery = await notesCollection
          .where(
            'originatorInfo.depositTransactionId',
            isEqualTo: transactionId,
          )
          .get();

      if (depositQuery.docs.isEmpty)
        throw Exception("No notes found for this transaction ID.");

      final WriteBatch batch = _firestore.batch();
      for (var doc in depositQuery.docs) {
        batch.update(doc.reference, {'status': 'blocked'});
      }
      await batch.commit();
      return depositQuery.docs.length;
    }

    if (createdNoteSerials.isEmpty) {
      return 0; // No notes were created by this transaction to block.
    }

    // Now, find all notes that have these serial numbers.
    // Firestore 'whereIn' queries are limited to 30 items. For more, you'd need multiple queries.
    final notesToBlockSnapshot = await notesCollection
        .where('serialNumber', whereIn: createdNoteSerials)
        .get();

    if (notesToBlockSnapshot.docs.isEmpty) return 0;

    final WriteBatch batch = _firestore.batch();
    for (var doc in notesToBlockSnapshot.docs) {
      batch.update(doc.reference, {'status': 'blocked'});
    }
    await batch.commit();
    return notesToBlockSnapshot.docs.length;
  }

  List<Map<String, double>> _calculateNoteDistribution(double amount) {
    final List<double> denominations = [
      1000,
      500,
      200,
      100,
      50,
      20,
      10,
      5,
      2,
      1,
    ];
    final List<Map<String, double>> notes = [];
    double remainingAmount = amount.floorToDouble();

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
