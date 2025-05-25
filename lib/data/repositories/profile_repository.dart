import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProfileRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> fetchUserFromFirestore() async {
    try {
      final userData = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      final user = UserModel.fromJson(userData.data()!);
      debugPrint("User fetched from Firestore: ${user.userEmail}");
      return user;
    } catch (error) {
      debugPrint("Error signing in with Google: $error");
      throw Exception(error);
    }
  }
}
