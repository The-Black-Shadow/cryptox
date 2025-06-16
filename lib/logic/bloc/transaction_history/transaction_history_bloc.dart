import 'package:bloc/bloc.dart';
import 'package:cryptox/data/models/transaction_record_model.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:equatable/equatable.dart';

part 'transaction_history_event.dart';
part 'transaction_history_state.dart';

class TransactionHistoryBloc extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  final WalletRepository _walletRepository;

  TransactionHistoryBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(TransactionHistoryInitial()) {
    on<LoadUserTransactions>(_onLoadUserTransactions);
  }

  Future<void> _onLoadUserTransactions(
    LoadUserTransactions event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    emit(TransactionHistoryLoading());
    try {
      final transactions = await _walletRepository.fetchUserTransactions();
      emit(TransactionHistoryLoaded(transactions));
    } catch (e) {
      emit(TransactionHistoryError(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}