part of 'digital_note_bloc.dart';

sealed class DigitalNoteEvent extends Equatable {
  const DigitalNoteEvent();

  @override
  List<Object> get props => [];
}

/// Dispatched to load the user's digital notes.
class LoadDigitalNotes extends DigitalNoteEvent {}
