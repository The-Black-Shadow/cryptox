import 'package:bloc/bloc.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'signin_event.dart';
part 'signin_state.dart';

class SigninBloc extends Bloc<SigninEvent, SigninState> {
  final AuthRepository repository;

  SigninBloc(this.repository) : super(SigninInitial()) {
    on<RequestGoogleSigninEvent>(_onRequestGoogleSigninEvent);
    on<RequestEmailSigninEvent>(_onRequestEmailSigninEvent);
  }

  Future<void> _onRequestGoogleSigninEvent(
    RequestGoogleSigninEvent event,
    Emitter<SigninState> emit,
  ) async {
    emit(SigninLoading());
    try {
      // 2. This method now returns a UserModel? which includes the role
      final UserModel? userModel = await repository.signInWithGoogle();
      debugPrint(
        "Signed-in user: ${userModel?.userEmail}, Role: ${userModel?.role}",
      );

      if (userModel != null) {
        // 3. Pass the complete userModel object to the success state
        emit(SigninSuccess(userModel));
      } else {
        // This handles cases where the user cancels the sign-in flow
        emit(const SigninFailure('Google Sign-In failed or was canceled.'));
      }
    } catch (e) {
      // This handles any other errors during the process
      emit(SigninFailure(e.toString()));
    }
  }

  Future<void> _onRequestEmailSigninEvent(
    RequestEmailSigninEvent event,
    Emitter<SigninState> emit,
  ) async {
    emit(SigninLoading());
    try {
      final UserModel? userModel = await repository.signInWithEmail(
        event.email,
        event.password,
      );
      debugPrint(
        "Signed-in user: ${userModel?.userEmail}, Role: ${userModel?.role}",
      );

      if (userModel != null) {
        emit(SigninSuccess(userModel));
      } else {
        emit(
          const SigninFailure(
            'Email sign-in failed. Please check your credentials.',
          ),
        );
      }
    } catch (e) {
      emit(SigninFailure(e.toString()));
    }
  }
}
