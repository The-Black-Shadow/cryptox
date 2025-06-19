import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/data/repositories/admin_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'admin_digital_note_event.dart';
part 'admin_digital_note_state.dart';

class AdminDigitalNoteBloc
    extends Bloc<AdminDigitalNoteEvent, AdminDigitalNoteState> {
  final AdminRepository _adminRepository;
  final FirebaseAuth _firebaseAuth;

  AdminDigitalNoteBloc({
    required AdminRepository adminRepository,
    FirebaseAuth? firebaseAuth,
  }) : _adminRepository = adminRepository,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       super(AdminDigitalNoteInitial()) {
    on<SearchUserByEmail>(_onSearchUserByEmail, transformer: restartable());
    on<DepositNotesToUser>(_onDepositNotesToUser);
    on<UpdateNoteStatusRequested>(_onUpdateNoteStatus);
    on<ClearNoteSearch>((event, emit) => emit(AdminDigitalNoteInitial()));
  }

  Future<void> _onSearchUserByEmail(
    SearchUserByEmail event,
    Emitter<AdminDigitalNoteState> emit,
  ) async {
    if (event.email.trim().isEmpty) {
      emit(AdminDigitalNoteInitial());
      return;
    }
    emit(AdminDigitalNoteLoading());
    try {
      final userSearchResult = await _adminRepository.findUserByEmail(
        event.email,
      );
      if (userSearchResult == null) {
        throw Exception("User not found.");
      }
      final String userId = userSearchResult['id'];
      final UserModel user = userSearchResult['user'];

      final notes = await _adminRepository.fetchUserDigitalNotes(userId);
      final totalBalance = notes.fold(
        0.0,
        (sum, note) => sum + note.denomination,
      );

      emit(
        UserNotesLoaded(
          userId: userId,
          user: user,
          notes: notes,
          totalBalance: totalBalance,
        ),
      );
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _onDepositNotesToUser(
    DepositNotesToUser event,
    Emitter<AdminDigitalNoteState> emit,
  ) async {
    final currentState = state;
    if (currentState is! UserNotesLoaded) {
      // This case should ideally not happen if UI is correct, but as a fallback:
      emit(const AdminDigitalNoteError("No user selected to deposit to."));
      return;
    }

    emit(
      ActionInProgress(
        userId: currentState.userId,
        user: currentState.user,
        notes: currentState.notes,
        totalBalance: currentState.totalBalance,
      ),
    );

    try {
      final admin = _firebaseAuth.currentUser;
      if (admin == null) throw Exception("Admin not authenticated.");

      await _adminRepository.depositDigitalNotes(
        userId: event.userId,
        totalAmount: event.amount,
        adminId: admin.uid,
        adminEmail: admin.email ?? 'admin@cryptox.com',
      );

      emit(ActionSuccess("Successfully deposited ${event.amount} to user."));

      // After success, re-search the user to show their updated balance.
      add(SearchUserByEmail(currentState.user.userEmail));
    } catch (e) {
      // --- THIS IS THE FIX ---
      // On failure, emit the error state but DO NOT revert to the loaded state here.
      // Let the UI decide what to do next based on the error.
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _onUpdateNoteStatus(
    UpdateNoteStatusRequested event,
    Emitter<AdminDigitalNoteState> emit,
  ) async {
    final currentState = state;
    if (currentState is! UserNotesLoaded) return;

    emit(
      ActionInProgress(
        userId: currentState.userId,
        user: currentState.user,
        notes: currentState.notes,
        totalBalance: currentState.totalBalance,
      ),
    );

    try {
      await _adminRepository.updateNoteStatus(event.noteId, event.newStatus);
      emit(ActionSuccess("Note status updated successfully."));
      add(SearchUserByEmail(currentState.user.userEmail));
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
