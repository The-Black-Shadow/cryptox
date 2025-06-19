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

/// Dispatched when admin confirms a deposit to a user.
class DepositNotesToUser extends AdminDigitalNoteEvent {
  final String userId;
  final double amount;

  const DepositNotesToUser({required this.userId, required this.amount});
  @override
  List<Object> get props => [userId, amount];
}

/// Event to clear the search result and go back to the initial state.
class ClearSearch extends AdminDigitalNoteEvent {}
