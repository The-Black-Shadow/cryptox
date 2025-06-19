part of 'digital_note_bloc.dart';

sealed class DigitalNoteState extends Equatable {
  const DigitalNoteState();

  @override
  List<Object> get props => [];
}

final class DigitalNoteInitial extends DigitalNoteState {}

final class DigitalNoteLoading extends DigitalNoteState {}

final class DigitalNoteLoaded extends DigitalNoteState {
  final List<DigitalNoteModel> notes;
  final double totalBalance;

  const DigitalNoteLoaded({required this.notes, required this.totalBalance});

  @override
  List<Object> get props => [notes, totalBalance];
}

final class DigitalNoteError extends DigitalNoteState {
  final String message;

  const DigitalNoteError(this.message);

  @override
  List<Object> get props => [message];
}
