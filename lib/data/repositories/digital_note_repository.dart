import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/digital_note_model.dart';
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

  /// Fetches all 'active' digital notes for the current user.
  Future<List<DigitalNoteModel>> fetchCurrentUserNotes() async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    try {
      final querySnapshot = await _firestore
          .collection('digital_notes')
          .where('ownerUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active') // Only fetch active notes
          .orderBy('denomination', descending: true) // Show larger notes first
          .get();

      return querySnapshot.docs
          .map((doc) => DigitalNoteModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Error fetching digital notes: $e");
      throw Exception("Could not load your digital notes.");
    }
  }
}
