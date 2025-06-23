part of 'signin_bloc.dart';

sealed class SigninEvent extends Equatable {
  const SigninEvent();

  @override
  List<Object> get props => [];
}

class RequestGoogleSigninEvent extends SigninEvent {}

class RequestEmailSigninEvent extends SigninEvent {
  final String email;
  final String password;

  const RequestEmailSigninEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
