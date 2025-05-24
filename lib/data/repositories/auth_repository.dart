import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignIn = await GoogleSignIn().signIn();

      if (googleSignIn == null) {
        // User canceled the sign-in process
        debugPrint("User canceled the signin process.");
        return null;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignIn.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
      );

      final UserCredential authResult = await _auth.signInWithCredential(
        credential,
      );

      if (authResult.user != null) {
        createUserInDatabase(authResult.user!);
      }
      debugPrint('User: ${authResult.user?.email}');
      return authResult.user;
    } catch (error) {
      debugPrint("Error signing in with Google: $error");
      return null;
    }
  }

  Future<void> createUserInDatabase(User user) async {
    try {
      final data = UserModel(
        userName: user.displayName ?? 'No Name',
        userEmail: user.email ?? 'No Email',
        photoUrl: user.photoURL ?? '',
        phoneNumber: user.phoneNumber ?? '',
      );
      await _firestore.collection('users').doc(user.uid).set(data.toJson());
      debugPrint("User created in database: ${data.userEmail}");
    } catch (e) {
      debugPrint("Failed to create user in Firestore: $e");
    }
  }
}
