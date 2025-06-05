import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/crypto_balance_model.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/data/preference/local_preference.dart';
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
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      await _firestore.collection('users').doc(user.uid).get();
      final data = UserModel(
        userName: user.displayName ?? 'No Name',
        userEmail: user.email ?? 'No Email',
        photoUrl: user.photoURL ?? '',
        phoneNumber: user.phoneNumber ?? '+88017xxxxxxxx',
      );

      if (!userDoc.exists) {
        // User document does not exist, create it
        final data = UserModel(
          userName: user.displayName ?? 'No Name',
          userEmail: user.email ?? 'No Email',
          photoUrl: user.photoURL ?? '',
          phoneNumber: user.phoneNumber ?? '+88017xxxxxxxx',
        );

        await _firestore.collection('users').doc(user.uid).set(data.toJson());

        final cryptoBalance = CryptoBalance(
          bitcoin: 0.034,
          ethereum: 1.21,
          bnb: 0.5,
          x: 44.5,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cryptoBalance')
            .doc('balance')
            .set(cryptoBalance.toJson());

        debugPrint("User created in database: ${data.userEmail}");
      } else {
        debugPrint("User already exists in database: ${user.email}");
      }
      //also save user data in local preferences
      LocalPreferences.setString('userName', data.userName);
      LocalPreferences.setString('userEmail', data.userEmail);
      LocalPreferences.setString('photoUrl', data.photoUrl);
      LocalPreferences.setString('phoneNumber', data.phoneNumber);
      LocalPreferences.setString('uid', user.uid);
    } catch (e) {
      debugPrint("Failed to create user in Firestore: $e");
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await GoogleSignIn().signOut();

      // Clear locally stored user data
      await LocalPreferences.clear();

      debugPrint("User successfully signed out.");
    } catch (e) {
      debugPrint("Error during sign out: $e");
    }
  }
}
