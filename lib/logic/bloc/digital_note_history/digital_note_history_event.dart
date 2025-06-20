part of 'digital_note_history_bloc.dart';

sealed class DigitalNoteHistoryEvent extends Equatable {
  const DigitalNoteHistoryEvent();

  @override
  List<Object> get props => [];
}

class LoadNoteHistory extends DigitalNoteHistoryEvent {}
