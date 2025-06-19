part of 'admin_trace_bloc.dart';

sealed class AdminTraceEvent extends Equatable {
  const AdminTraceEvent();
  @override
  List<Object> get props => [];
}

class LoadRecentTransactions extends AdminTraceEvent {}

class TraceTransactionRequested extends AdminTraceEvent {
  final String transactionId;
  const TraceTransactionRequested(this.transactionId);
  @override
  List<Object> get props => [transactionId];
}

class TraceParcelForward extends AdminTraceEvent {
  final String parcelId;
  const TraceParcelForward(this.parcelId);
  @override
  List<Object> get props => [parcelId];
}

class BlockTransactionRequested extends AdminTraceEvent {
  final String transactionId;
  const BlockTransactionRequested(this.transactionId);
  @override
  List<Object> get props => [transactionId];
}
