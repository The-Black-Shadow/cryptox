import 'package:bloc/bloc.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository;
  ProfileBloc(this._authRepository) : super(ProfileInitial()) {
    on<LogoutEvent>((event, emit) async {
      // Handle logout logic here
      await _authRepository.signOut();
      debugPrint("User logged out successfully");
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Give time to mount
      // For example, clear user data from local storage or call a logout method from a repository
      emit(LogoutSuccess());
    });
  }
}
