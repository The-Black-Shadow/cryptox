part of 'signup_bloc.dart';

sealed class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object> get props => [];
}

class RequestEmailSignupEvent extends SignupEvent {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;

  const RequestEmailSignupEvent({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [username, email, password, confirmPassword];
}
