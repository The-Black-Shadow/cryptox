part of 'send_digital_note_bloc.dart';

sealed class SendDigitalNoteState extends Equatable {
  const SendDigitalNoteState();

  @override
  List<Object> get props => [];
}

final class SendDigitalNoteInitial extends SendDigitalNoteState {}

final class SendDigitalNoteInProgress extends SendDigitalNoteState {}

final class SendDigitalNoteSuccess extends SendDigitalNoteState {
  final String message;
  const SendDigitalNoteSuccess(this.message);
  @override
  List<Object> get props => [message];
}

final class SendDigitalNoteFailure extends SendDigitalNoteState {
  final String error;
  const SendDigitalNoteFailure(this.error);
  @override
  List<Object> get props => [error];
}
