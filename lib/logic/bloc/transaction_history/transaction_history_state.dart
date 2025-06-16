part of 'transaction_history_bloc.dart';

sealed class TransactionHistoryState extends Equatable {
  const TransactionHistoryState();
  
  @override
  List<Object> get props => [];
}

final class TransactionHistoryInitial extends TransactionHistoryState {}
final class TransactionHistoryLoading extends TransactionHistoryState {}

final class TransactionHistoryLoaded extends TransactionHistoryState {
  final List<TransactionRecordModel> transactions;

  const TransactionHistoryLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];
}

final class TransactionHistoryError extends TransactionHistoryState {
  final String message;

  const TransactionHistoryError(this.message);

  @override
  List<Object> get props => [message];
}