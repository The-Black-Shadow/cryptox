part of 'send_digital_note_bloc.dart';

sealed class SendDigitalNoteEvent extends Equatable {
  const SendDigitalNoteEvent();

  @override
  List<Object> get props => [];
}

class SendNotesSubmitted extends SendDigitalNoteEvent {
  final String recipientEmail;
  final double amount;

  const SendNotesSubmitted({
    required this.recipientEmail,
    required this.amount,
  });

  @override
  List<Object> get props => [recipientEmail, amount];
}