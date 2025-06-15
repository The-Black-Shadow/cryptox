part of 'signin_bloc.dart';

sealed class SigninState extends Equatable {
  const SigninState();

  @override
  List<Object> get props => [];
}

final class SigninInitial extends SigninState {}

final class SigninLoading extends SigninState {}

// --- MODIFIED STATE ---
// This state now holds the user's data, including their role.
final class SigninSuccess extends SigninState {
  final UserModel userModel;

  const SigninSuccess(this.userModel);

  @override
  List<Object> get props => [userModel];
}

final class SigninFailure extends SigninState {
  final String error;

  const SigninFailure(this.error);

  @override
  List<Object> get props => [error];
}
