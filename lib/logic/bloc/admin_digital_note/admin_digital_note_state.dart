part of 'admin_digital_note_bloc.dart';

sealed class AdminDigitalNoteState extends Equatable {
  const AdminDigitalNoteState();
  
  @override
  List<Object> get props => [];
}

final class AdminDigitalNoteInitial extends AdminDigitalNoteState {}
final class AdminDigitalNoteLoading extends AdminDigitalNoteState {}

/// State when a user's notes are successfully loaded and displayed.
final class UserNotesLoaded extends AdminDigitalNoteState {
  final UserModel user;
  final List<DigitalNoteModel> notes;
  final double totalBalance;
  
  const UserNotesLoaded({required this.user, required this.notes, required this.totalBalance});
  
  @override
  List<Object> get props => [user, notes, totalBalance];
}

/// State while a deposit is being processed.
final class DepositInProgress extends UserNotesLoaded {
  const DepositInProgress({
    required super.user,
    required super.notes,
    required super.totalBalance,
  });
}

final class DepositSuccess extends AdminDigitalNoteState {
  final String message;
  const DepositSuccess(this.message);
  @override
  List<Object> get props => [message];
}

final class AdminDigitalNoteError extends AdminDigitalNoteState {
  final String message;
  const AdminDigitalNoteError(this.message);
  @override
  List<Object> get props => [message];
}