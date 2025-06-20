import 'package:bloc/bloc.dart';
import 'package:cryptox/data/models/digital_note_transaction_model.dart';
import 'package:cryptox/data/repositories/digital_note_repository.dart';
import 'package:equatable/equatable.dart';

part 'digital_note_history_event.dart';
part 'digital_note_history_state.dart';

class DigitalNoteHistoryBloc
    extends Bloc<DigitalNoteHistoryEvent, DigitalNoteHistoryState> {
  final DigitalNoteRepository _digitalNoteRepository;

  DigitalNoteHistoryBloc({required DigitalNoteRepository digitalNoteRepository})
    : _digitalNoteRepository = digitalNoteRepository,
      super(DigitalNoteHistoryInitial()) {
    on<LoadNoteHistory>(_onLoadNoteHistory);
  }

  Future<void> _onLoadNoteHistory(
    LoadNoteHistory event,
    Emitter<DigitalNoteHistoryState> emit,
  ) async {
    emit(DigitalNoteHistoryLoading());
    try {
      final transactions = await _digitalNoteRepository
          .fetchUserDigitalNoteTransactions();
      emit(DigitalNoteHistoryLoaded(transactions));
    } catch (e) {
      emit(
        DigitalNoteHistoryError(e.toString().replaceFirst("Exception: ", "")),
      );
    }
  }
}
