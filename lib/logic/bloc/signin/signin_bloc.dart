import 'package:bloc/bloc.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'signin_event.dart';
part 'signin_state.dart';

class SigninBloc extends Bloc<SigninEvent, SigninState> {
  final AuthRepository repository;

  SigninBloc(this.repository) : super(SigninInitial()) {
    on<RequestGoogleSigninEvent>((event, emit) async {
      emit(SigninLoading());

      final user = await repository.signInWithGoogle();
      debugPrint("User: ${user?.email}");

      if (user != null) {
        emit(SigninSuccess());
      } else {
        emit(const SigninFailure('Google Sign-In failed or was cancelled.'));
      }
    });
  }
}
