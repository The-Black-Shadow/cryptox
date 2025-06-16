import 'package:bloc/bloc.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc(AuthRepository read) : super(SignupInitial()) {
    on<SignupEvent>((event, emit) {});
  }
}
