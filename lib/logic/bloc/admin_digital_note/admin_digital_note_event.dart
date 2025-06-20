part of 'admin_digital_note_bloc.dart';

sealed class AdminDigitalNoteEvent extends Equatable {
  const AdminDigitalNoteEvent();

  @override
  List<Object> get props => [];
}

/// Dispatched when admin searches for a user by email.
class SearchUserByEmail extends AdminDigitalNoteEvent {
  final String email;
  const SearchUserByEmail(this.email);
  @override
  List<Object> get props => [email];
}

class DepositNotesToUser extends AdminDigitalNoteEvent {
  final String userId;
  final double amount;
  const DepositNotesToUser({required this.userId, required this.amount});
  @override
  List<Object> get props => [userId, amount];
}

class UpdateNoteStatusRequested extends AdminDigitalNoteEvent {
  final String noteId;
  final String newStatus;
  const UpdateNoteStatusRequested({
    required this.noteId,
    required this.newStatus,
  });
  @override
  List<Object> get props => [noteId, newStatus];
}

class ClearNoteSearch extends AdminDigitalNoteEvent {}

class SearchTransactionById extends AdminDigitalNoteEvent {
  final String transactionId;
  const SearchTransactionById(this.transactionId);
  @override
  List<Object> get props => [transactionId];
}

class BlockNotesByTransactionId extends AdminDigitalNoteEvent {
  final String transactionId;
  const BlockNotesByTransactionId(this.transactionId);
  @override
  List<Object> get props => [transactionId];
}

class EnableNotesByTransactionId extends AdminDigitalNoteEvent {
  final String transactionId;
  const EnableNotesByTransactionId(this.transactionId);
  @override
  List<Object> get props => [transactionId];
}
