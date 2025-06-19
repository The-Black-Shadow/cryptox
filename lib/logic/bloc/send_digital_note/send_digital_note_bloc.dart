import 'package:bloc/bloc.dart';
import 'package:cryptox/data/repositories/digital_note_repository.dart';
import 'package:equatable/equatable.dart';

part 'send_digital_note_event.dart';
part 'send_digital_note_state.dart';

class SendDigitalNoteBloc
    extends Bloc<SendDigitalNoteEvent, SendDigitalNoteState> {
  final DigitalNoteRepository _digitalNoteRepository;

  SendDigitalNoteBloc({required DigitalNoteRepository digitalNoteRepository})
    : _digitalNoteRepository = digitalNoteRepository,
      super(SendDigitalNoteInitial()) {
    on<SendNotesSubmitted>(_onSendNotesSubmitted);
  }

  Future<void> _onSendNotesSubmitted(
    SendNotesSubmitted event,
    Emitter<SendDigitalNoteState> emit,
  ) async {
    emit(SendDigitalNoteInProgress());
    try {
      await _digitalNoteRepository.sendDigitalNotes(
        recipientEmail: event.recipientEmail,
        amountToSend: event.amount,
      );
      emit(
        SendDigitalNoteSuccess(
          'Successfully sent ${event.amount} to ${event.recipientEmail}',
        ),
      );
    } catch (e) {
      emit(
        SendDigitalNoteFailure(e.toString().replaceFirst("Exception: ", "")),
      );
    }
  }
}
