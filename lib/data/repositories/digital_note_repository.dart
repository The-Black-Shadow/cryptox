import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/models/digital_note_transaction_model.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DigitalNoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  DigitalNoteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<List<DigitalNoteModel>> fetchCurrentUserNotes() async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    try {
      final querySnapshot = await _firestore
          .collection('digital_notes')
          .where('ownerUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('denomination', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DigitalNoteModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Error fetching digital notes: $e");
      throw Exception("Could not load your digital notes.");
    }
  }

  /// Fetches all digital note transactions for the current user.
  Future<List<DigitalNoteTransactionModel>>
  fetchUserDigitalNoteTransactions() async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    try {
      // Query for transactions where the user was the sender
      final sentQuery = _firestore
          .collection('digital_note_transactions')
          .where('senderId', isEqualTo: currentUser.uid)
          .get();

      // Query for transactions where the user was the recipient
      final receivedQuery = _firestore
          .collection('digital_note_transactions')
          .where('recipientId', isEqualTo: currentUser.uid)
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
            (doc) => DigitalNoteTransactionModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      // Sort the combined list by timestamp, newest first
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return transactions;
    } catch (e) {
      debugPrint("Error fetching digital note transactions: $e");
      throw Exception("Could not load transaction history.");
    }
  }

  Future<void> sendDigitalNotes({
    required String recipientEmail,
    required double amountToSend,
  }) async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) throw Exception('User not logged in.');
    if (currentUser.email == recipientEmail)
      throw Exception('You cannot send notes to yourself.');
    if (amountToSend <= 0) throw Exception('Amount must be positive.');

    final recipientQuery = await _firestore
        .collection('users')
        .where('user_email', isEqualTo: recipientEmail.trim())
        .limit(1)
        .get();
    if (recipientQuery.docs.isEmpty)
      throw Exception('Recipient user not found.');
    final recipientId = recipientQuery.docs.first.id;
    final recipientInfo = UserModel.fromJson(recipientQuery.docs.first.data());

    final notesCollectionRef = _firestore.collection('digital_notes');
    final transactionLedgerRef = _firestore
        .collection('digital_note_transactions')
        .doc();

    final senderNotesQuery = await notesCollectionRef
        .where('ownerUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'active')
        .get();

    List<DigitalNoteModel> allSenderNotes = senderNotesQuery.docs
        .map((d) => DigitalNoteModel.fromFirestore(d))
        .toList();
    allSenderNotes.sort((a, b) => a.denomination.compareTo(b.denomination));

    List<DigitalNoteModel> notesToUse = [];
    double collectedAmount = 0;
    for (var note in allSenderNotes) {
      if (collectedAmount < amountToSend) {
        notesToUse.add(note);
        collectedAmount += note.denomination;
      }
    }

    if (collectedAmount < amountToSend)
      throw Exception("Insufficient balance to send this amount.");

    return _firestore.runTransaction((transaction) async {
      double amountStillNeeded = amountToSend;
      final List<String> consumedNoteIdsForLedger = [];
      final List<String> createdNoteIdsForLedger = [];

      for (var note in notesToUse) {
        if (amountStillNeeded <= 0) break; // Should not happen, but for safety

        final noteRef = notesCollectionRef.doc(note.noteId);
        final bool isExactOrSmaller = note.denomination <= amountStillNeeded;

        // --- THIS IS THE NEW LOGIC BRANCH ---
        if (isExactOrSmaller) {
          // --- PATH A: DIRECT TRANSFER ---
          // This note is used in its entirety. Just change the owner.
          transaction.update(noteRef, {
            'ownerUserId': recipientId,
            'history': FieldValue.arrayUnion([
              {
                'fromUserId': currentUser.uid,
                'fromUserEmail': currentUser.email,
                'toUserId': recipientId,
                'timestamp': Timestamp.now(),
                'transactionId': transactionLedgerRef.id,
              },
            ]),
          });
          amountStillNeeded -= note.denomination;
          consumedNoteIdsForLedger.add(note.serialNumber);
          createdNoteIdsForLedger.add(
            note.serialNumber,
          ); // The same note is "created" for the new owner
        } else {
          // --- PATH B: MAKE CHANGE ---
          // This is the last note needed, and it must be broken into pieces.

          // 1. Mark the original note as "spent"
          transaction.update(noteRef, {'status': 'spent'});
          consumedNoteIdsForLedger.add(note.serialNumber);

          // 2. Create the final piece for the recipient
          final recipientPieceAmount = amountStillNeeded;
          final recipientNotesDistribution = _calculateNoteDistribution(
            recipientPieceAmount,
          );
          for (var noteData in recipientNotesDistribution) {
            final newNoteRef = notesCollectionRef.doc();
            final newSerialNumber = 'DN ${newNoteRef.id}'.toUpperCase();
            final newNote = DigitalNoteModel(
              noteId: newNoteRef.id,
              serialNumber: newSerialNumber,
              denomination: noteData['denomination']!,
              ownerUserId: recipientId,
              status: 'active',
              originatorInfo: note.originatorInfo,
              history: [
                {
                  'fromUserId': currentUser.uid,
                  'fromUserEmail': currentUser.email,
                  'toUserId': recipientId,
                  'timestamp': Timestamp.now(),
                  'transactionId': transactionLedgerRef.id,
                },
              ],
            );
            transaction.set(newNoteRef, newNote.toJson());
            createdNoteIdsForLedger.add(newSerialNumber);
          }

          // 3. Create the "change" back to the sender
          final changeAmount = note.denomination - amountStillNeeded;
          final changeNotesDistribution = _calculateNoteDistribution(
            changeAmount,
          );
          for (var noteData in changeNotesDistribution) {
            final newNoteRef = notesCollectionRef.doc();
            final newSerialNumber = 'DN ${newNoteRef.id}'.toUpperCase();
            final newNote = DigitalNoteModel(
              noteId: newNoteRef.id,
              serialNumber: newSerialNumber,
              denomination: noteData['denomination']!,
              ownerUserId: currentUser.uid,
              status: 'active',
              originatorInfo: note.originatorInfo,
              history: [
                {
                  'fromUserId': currentUser.uid,
                  'fromUserEmail': currentUser.email,
                  'toUserId': currentUser.uid,
                  'timestamp': Timestamp.now(),
                  'transactionId': transactionLedgerRef.id,
                },
              ],
            );
            transaction.set(newNoteRef, newNote.toJson());
            createdNoteIdsForLedger.add(newSerialNumber);
          }

          amountStillNeeded = 0; // We are done
        }
      }

      // Log the master transaction
      transaction.set(transactionLedgerRef, {
        'transactionId': transactionLedgerRef.id,
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
        'recipientId': recipientId,
        'recipientEmail': recipientInfo.userEmail,
        'totalSentAmount': amountToSend,
        'timestamp': Timestamp.now(),
        'consumedNoteIds': consumedNoteIdsForLedger,
        'createdNoteIds': createdNoteIdsForLedger,
      });
    });
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
