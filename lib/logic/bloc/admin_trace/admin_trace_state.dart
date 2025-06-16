part of 'admin_trace_bloc.dart';

sealed class AdminTraceState extends Equatable {
  const AdminTraceState();

  @override
  List<Object> get props => [];
}

final class AdminTraceInitial extends AdminTraceState {}
final class AdminTraceLoading extends AdminTraceState {}

/// State representing a list of transactions (either recent or search results).
final class AdminTraceLoaded extends AdminTraceState {
  final List<TransactionRecordModel> transactions;

  const AdminTraceLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];
}

final class AdminTraceError extends AdminTraceState {
  final String message;

  const AdminTraceError(this.message);

  @override
  List<Object> get props => [message];
}