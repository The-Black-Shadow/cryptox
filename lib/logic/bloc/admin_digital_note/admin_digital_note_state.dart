part of 'admin_digital_note_bloc.dart';

sealed class AdminDigitalNoteState extends Equatable {
  const AdminDigitalNoteState();

  @override
  List<Object> get props => [];
}

final class AdminDigitalNoteInitial extends AdminDigitalNoteState {}

final class AdminDigitalNoteLoading extends AdminDigitalNoteState {}

final class UserNotesLoaded extends AdminDigitalNoteState {
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

final class ActionInProgress extends UserNotesLoaded {
  const ActionInProgress({
    required super.userId,
    required super.user,
    required super.notes,
    required super.totalBalance,
  });
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
