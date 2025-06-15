import 'package:bloc/bloc.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final AuthRepository _authRepository; 
  final FirebaseAuth _firebaseAuth;

 //Update the constructor to accept the repository
  SplashCubit(this._authRepository, this._firebaseAuth) : super(SplashInitial());

  //Make the method async and update its logic
  void startSplash() async {
    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // User is logged in, now fetch their profile to get the role
        final userModel = await _authRepository.fetchUserProfile();
        emit(SplashEnd(userModel: userModel)); // Emit state with user data
      } else {
        // No user is logged in
        emit(SplashEnd(userModel: null)); // Emit state with null user
      }
    } catch (e) {
      await _authRepository.signOut();
      emit(SplashEnd(userModel: null));
    }
  }
}
