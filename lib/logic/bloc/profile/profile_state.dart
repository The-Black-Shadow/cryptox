part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

final class ProfileInitial extends ProfileState {}
final class ProfileLoading extends ProfileState {}
final class ProfileUpdating extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final UserModel user;
  const ProfileLoaded(this.user);
  @override
  List<Object> get props => [user];
}

final class ProfileUpdateSuccess extends ProfileState {}
final class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object> get props => [message];
}

final class LogoutSuccess extends ProfileState {}
