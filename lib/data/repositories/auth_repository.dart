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

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        debugPrint("User canceled the signin process.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
      );

      final UserCredential authResult = await _auth.signInWithCredential(
        credential,
      );
      final User? user = authResult.user;

      if (user != null) {
        // This now creates the user if they don't exist
        await createUserInDatabase(user, null);
        // After signing in, fetch the full profile (which includes the role)
        final userModel = await fetchUserProfile();
        return userModel;
      }
      return null;
    } catch (error) {
      debugPrint("Error signing in with Google: $error");
      return null;
    }
  }

  //signUp with email
  Future<UserModel?> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // This now creates the user if they don't exist
        await createUserInDatabase(user, username);
        // After signing in, fetch the full profile (which includes the role)
        final userModel = await fetchUserProfile();
        return userModel;
      }
      return null;
    } catch (error) {
      debugPrint("Error signing up with email: $error");
      return null;
    }
  }

  //signIn with email
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // After signing in, fetch the full profile (which includes the role)
        final userModel = await fetchUserProfile();
        return userModel;
      }
      return null;
    } catch (error) {
      debugPrint("Error signing in with email: $error");
      return null;
    }
  }

  Future<void> createUserInDatabase(User user, String? username) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      await _firestore.collection('users').doc(user.uid).get();

      final data = UserModel(
        userName: user.displayName ?? 'No Name',
        userEmail: user.email ?? 'No Email',
        photoUrl: user.photoURL ?? '',
        phoneNumber: user.phoneNumber ?? '+88017xxxxxxxx',
        role: 'user', // Default role for new users
      );

      if (!userDoc.exists) {
        // User document does not exist, create it
        final data = UserModel(
          userName: user.displayName ?? username!,
          userEmail: user.email ?? 'No Email',
          photoUrl: user.photoURL ?? '',
          phoneNumber: user.phoneNumber ?? '+88017xxxxxxxx',
          role: 'user', // Default role for new users
        );

        await _firestore.collection('users').doc(user.uid).set(data.toJson());

        final cryptoBalance = CryptoBalance(
          bitcoin: 0.034,
          ethereum: 1.21,
          bnb: 0.5,
          x: 44.5,
          tether: 150.0,
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
      LocalPreferences.setString('role', data.role); // Save role as well
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

  // Fetches the UserModel from Firestore for the current user
  Future<UserModel> fetchUserProfile() async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final user = UserModel.fromJson(docSnapshot.data()!);
        debugPrint("User fetched from Firestore: ${user.userEmail}");
        return user;
      } else {
        throw Exception("User document not found in Firestore.");
      }
    } catch (error) {
      debugPrint("Error fetching user profile: $error");
      throw Exception(error);
    }
  }

  // Updates specific fields in the user's document
  Future<void> updateUserProfile(Map<String, dynamic> dataToUpdate) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(dataToUpdate);
      debugPrint("User profile updated successfully with data: $dataToUpdate");
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      throw Exception("Failed to update profile.");
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint("Password reset email sent to: $email");
    } catch (error) {
      debugPrint("Error sending password reset email: $error");
      throw Exception(
        "Failed to send password reset email. Please check the email address.",
      );
    }
  }
}
