part of 'admin_digital_note_bloc.dart';

sealed class AdminDigitalNoteState extends Equatable {
  const AdminDigitalNoteState();

  @override
  List<Object> get props => [];
}

final class AdminDigitalNoteInitial extends AdminDigitalNoteState {}

final class AdminDigitalNoteLoading extends AdminDigitalNoteState {}

class UserNotesLoaded extends AdminDigitalNoteState {
  final String userId;
  final UserModel user;
  final List<DigitalNoteModel> notes;
  final double totalBalance;

  const UserNotesLoaded({
    required this.userId,
    required this.user,
    required this.notes,
    required this.totalBalance,
  });

  @override
  List<Object> get props => [userId, user, notes, totalBalance];
}

class TransactionNotesLoaded extends AdminDigitalNoteState {
  final String transactionId;
  final List<DigitalNoteModel> notes;

  const TransactionNotesLoaded({
    required this.transactionId,
    required this.notes,
  });

  @override
  List<Object> get props => [transactionId, notes];
}

// This state holds the previous data while an action is happening
final class ActionInProgress extends AdminDigitalNoteState {
  final AdminDigitalNoteState previousState;
  const ActionInProgress(this.previousState);
  @override
  List<Object> get props => [previousState];
}

final class ActionSuccess extends AdminDigitalNoteState {
  final String message;
  const ActionSuccess(this.message);
  @override
  List<Object> get props => [message];
}

final class AdminDigitalNoteError extends AdminDigitalNoteState {
  final String message;
  const AdminDigitalNoteError(this.message);
  @override
  List<Object> get props => [message];
}
