import 'package:bloc/bloc.dart';
import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/repositories/digital_note_repository.dart';
import 'package:equatable/equatable.dart';

part 'digital_note_event.dart';
part 'digital_note_state.dart';

class DigitalNoteBloc extends Bloc<DigitalNoteEvent, DigitalNoteState> {
  final DigitalNoteRepository _digitalNoteRepository;

  DigitalNoteBloc({required DigitalNoteRepository digitalNoteRepository})
    : _digitalNoteRepository = digitalNoteRepository,
      super(DigitalNoteInitial()) {
    on<LoadDigitalNotes>(_onLoadDigitalNotes);
  }

  Future<void> _onLoadDigitalNotes(
    LoadDigitalNotes event,
    Emitter<DigitalNoteState> emit,
  ) async {
    emit(DigitalNoteLoading());
    try {
      final notes = await _digitalNoteRepository.fetchCurrentUserNotes();

      // Calculate the total balance from the fetched notes
      final double totalBalance = notes.fold(
        0.0,
        (sum, note) => sum + note.denomination,
      );

      emit(DigitalNoteLoaded(notes: notes, totalBalance: totalBalance));
    } catch (e) {
      emit(DigitalNoteError(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
