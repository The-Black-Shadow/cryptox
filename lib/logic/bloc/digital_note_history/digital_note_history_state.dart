part of 'digital_note_history_bloc.dart';

sealed class DigitalNoteHistoryState extends Equatable {
  const DigitalNoteHistoryState();

  @override
  List<Object> get props => [];
}

final class DigitalNoteHistoryInitial extends DigitalNoteHistoryState {}

final class DigitalNoteHistoryLoading extends DigitalNoteHistoryState {}

final class DigitalNoteHistoryLoaded extends DigitalNoteHistoryState {
  final List<DigitalNoteTransactionModel> transactions;
  const DigitalNoteHistoryLoaded(this.transactions);
  @override
  List<Object> get props => [transactions];
}

final class DigitalNoteHistoryError extends DigitalNoteHistoryState {
  final String message;
  const DigitalNoteHistoryError(this.message);
  @override
  List<Object> get props => [message];
}