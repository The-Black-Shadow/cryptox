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
    on<SearchTransactionById>(
      _onSearchTransactionById,
      transformer: restartable(),
    );
    on<BlockNotesByTransactionId>(_onBlockNotesByTransactionId);
    on<EnableNotesByTransactionId>(_onEnableNotesByTransactionId);
  }

  Future<void> _onSearchTransactionById(
    SearchTransactionById event,
    Emitter<AdminDigitalNoteState> emit,
  ) async {
    if (event.transactionId.trim().isEmpty) {
      emit(AdminDigitalNoteInitial());
      return;
    }
    emit(AdminDigitalNoteLoading());
    try {
      // This call now uses the corrected repository logic
      final notes = await _adminRepository.fetchNotesByTransactionId(
        event.transactionId,
      );
      if (notes.isEmpty) {
        throw Exception("No notes found for this transaction ID.");
      }
      emit(
        TransactionNotesLoaded(
          transactionId: event.transactionId,
          notes: notes,
        ),
      );
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _onBlockNotesByTransactionId(
    BlockNotesByTransactionId event,
    Emitter<AdminDigitalNoteState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionNotesLoaded) return;

    emit(ActionInProgress(currentState));
    try {
      final count = await _adminRepository.blockNotesByTransaction(
        event.transactionId,
      );
      emit(ActionSuccess("$count note(s) have been blocked."));
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
      emit(currentState); // Revert on error
    }
  }

  Future<void> _onEnableNotesByTransactionId(
    EnableNotesByTransactionId event,
    Emitter<AdminDigitalNoteState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionNotesLoaded) return;

    emit(ActionInProgress(currentState));
    try {
      final count = await _adminRepository.enableNotesByTransaction(
        event.transactionId,
      );
      emit(ActionSuccess("$count note(s) have been enabled."));
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
      emit(currentState); // Revert on error
    }
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
    if (currentState is! UserNotesLoaded) return;

    emit(ActionInProgress(currentState)); // Pass previous state
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
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
      emit(currentState); // Revert on error
    }
  }

  Future<void> _onUpdateNoteStatus(
    UpdateNoteStatusRequested event,
    Emitter<AdminDigitalNoteState> emit,
  ) async {
    final currentState = state;
    if (currentState is! UserNotesLoaded &&
        currentState is! TransactionNotesLoaded) {
      return;
    }

    emit(ActionInProgress(currentState));
    try {
      await _adminRepository.updateNoteStatus(event.noteId, event.newStatus);
      emit(ActionSuccess("Note status updated successfully."));
    } catch (e) {
      emit(AdminDigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
      emit(currentState); // Revert on error
    }
  }
}
