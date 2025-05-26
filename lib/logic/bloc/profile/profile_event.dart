part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class FetchProfileEvent extends ProfileEvent {
  const FetchProfileEvent();

  @override
  List<Object> get props => [];
}

class LogoutEvent extends ProfileEvent {
  const LogoutEvent();

  @override
  List<Object> get props => [];
}