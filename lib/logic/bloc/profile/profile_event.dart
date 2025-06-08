part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

// Event to fetch the user's profile data
class FetchProfile extends ProfileEvent {}

// Event to update the user's profile data
class UpdateProfile extends ProfileEvent {
  final Map<String, dynamic> dataToUpdate;
  const UpdateProfile(this.dataToUpdate);
  @override
  List<Object> get props => [dataToUpdate];
}

// Event for logging out
class LogoutEvent extends ProfileEvent {}
