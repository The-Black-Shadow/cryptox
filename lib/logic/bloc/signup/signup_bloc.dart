// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:cryptox/data/repositories/auth_repository.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  AuthRepository authRepository;
  SignupBloc(this.authRepository) : super(SignupInitial()) {
    on<RequestEmailSignupEvent>((event, emit) async {
      emit(SignupLoading());
      try {
        await authRepository.signUpWithEmail(
          event.email,
          event.password,
          event.username,
        );
        emit(SignupSuccess());
      } catch (e) {
        emit(SignupFailure(e.toString()));
      }
    });
  }
}
