import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    on<ClearSearch>((event, emit) => emit(AdminDigitalNoteInitial()));
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
      final user = await _adminRepository.findUserByEmail(event.email);
      if (user == null) {
        throw Exception("User not found.");
      }
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('user_email', isEqualTo: event.email)
          .get();
      final userId = userQuery.docs.first.id;

      final notes = await _adminRepository.fetchUserDigitalNotes(userId);
      final totalBalance = notes.fold(
        0.0,
        (sum, note) => sum + note.denomination,
      );

      emit(
        UserNotesLoaded(user: user, notes: notes, totalBalance: totalBalance),
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
    if (currentState is UserNotesLoaded) {
      emit(
        DepositInProgress(
          user: currentState.user,
          notes: currentState.notes,
          totalBalance: currentState.totalBalance,
        ),
      );
    } else {
      emit(AdminDigitalNoteLoading());
    }

    try {
      final admin = _firebaseAuth.currentUser;
      if (admin == null) throw Exception("Admin not authenticated.");

      await _adminRepository.depositDigitalNotes(
        userId: event.userId,
        totalAmount: event.amount,
        adminId: admin.uid,
        adminEmail: admin.email ?? 'admin@cryptox.com',
      );

      emit(DepositSuccess("Successfully deposited ${event.amount} to user."));

      if (currentState is UserNotesLoaded) {
        add(SearchUserByEmail(currentState.user.userEmail));
      } else {
        emit(AdminDigitalNoteInitial());
      }
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
      if (currentState is UserNotesLoaded) {
        emit(currentState);
      }
    }
  }
}
