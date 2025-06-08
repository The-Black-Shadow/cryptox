import 'package:bloc/bloc.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/data/preference/local_preference.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository;

  ProfileBloc(this._authRepository) : super(ProfileInitial()) {
    on<FetchProfile>(_onFetchProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<LogoutEvent>(_onLogout);
  }

  // --- Private Helper Methods (from Step 1) ---
  Future<void> _saveUserToLocalPreferences(UserModel user) async {
    await LocalPreferences.setString('userName', user.userName);
    await LocalPreferences.setString('userEmail', user.userEmail);
    await LocalPreferences.setString('photoUrl', user.photoUrl);
    await LocalPreferences.setString('phoneNumber', user.phoneNumber);
    debugPrint("User profile cached in LocalPreferences.");
  }

  UserModel? _loadUserFromLocalPreferences() {
    final userName = LocalPreferences.getString('userName');
    final userEmail = LocalPreferences.getString('userEmail');
    if (userName.isEmpty || userEmail.isEmpty) {
      return null;
    }
    return UserModel(
      userName: userName,
      userEmail: userEmail,
      photoUrl: LocalPreferences.getString('photoUrl'),
      phoneNumber: LocalPreferences.getString('phoneNumber'),
    );
  }

  // --- MODIFIED EVENT HANDLERS ---
  Future<void> _onFetchProfile(
    FetchProfile event,
    Emitter<ProfileState> emit,
  ) async {
    // First, try to emit the cached data for an instant UI update
    final cachedUser = _loadUserFromLocalPreferences();
    if (cachedUser != null) {
      emit(ProfileLoaded(cachedUser));
      debugPrint("Profile loaded from cache.");
    } else {
      emit(ProfileLoading()); // Only show loader if no cache exists
    }

    // Then, always fetch the latest data from Firestore
    try {
      final freshUser = await _authRepository.fetchUserProfile();
      // Save the fresh data to the local cache
      await _saveUserToLocalPreferences(freshUser);
      // Emit the fresh data to the UI
      emit(ProfileLoaded(freshUser));
      debugPrint("Profile updated with fresh data from Firestore.");
    } catch (e) {
      // If fetching from Firestore fails, we still want to show the cached data if available.
      // We only emit an error if there was no cached data to begin with.
      if (cachedUser == null) {
        emit(ProfileError(e.toString().replaceFirst("Exception: ", "")));
      }
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    // To provide instant feedback, we can get the current state
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      // Cannot update if profile isn't loaded
      emit(const ProfileError("Profile not loaded, cannot update."));
      return;
    }

    emit(ProfileUpdating());
    try {
      // 1. Update Firestore
      await _authRepository.updateUserProfile(event.dataToUpdate);
      emit(ProfileUpdateSuccess()); // Signal success to UI for snackbar

      // 2. Re-fetch the complete user model to ensure data consistency
      final updatedUser = await _authRepository.fetchUserProfile();

      // 3. Save the newly fetched, complete profile to LocalPreferences
      await _saveUserToLocalPreferences(updatedUser);

      // 4. Emit the updated profile to the UI
      emit(ProfileLoaded(updatedUser));

    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst("Exception: ", "")));
      // Re-emit the last known good state so the UI doesn't get stuck on a loader
      emit(currentState);
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<ProfileState> emit,
  ) async {
    await _authRepository.signOut();
    debugPrint("User logged out successfully");
    emit(LogoutSuccess());
  }
}