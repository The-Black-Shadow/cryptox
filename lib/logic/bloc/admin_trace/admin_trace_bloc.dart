import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cryptox/data/models/transaction_record_model.dart';
import 'package:cryptox/data/repositories/admin_repository.dart';
import 'package:equatable/equatable.dart';

part 'admin_trace_event.dart';
part 'admin_trace_state.dart';

class AdminTraceBloc extends Bloc<AdminTraceEvent, AdminTraceState> {
  final AdminRepository _adminRepository;

  AdminTraceBloc({required AdminRepository adminRepository})
    : _adminRepository = adminRepository,
      super(AdminTraceInitial()) {
    on<LoadRecentTransactions>(_onLoadRecentTransactions);
    on<TraceTransactionRequested>(
      _onTraceTransactionRequested,
      transformer: restartable(),
    );
    on<TraceParcelForward>(_onTraceParcelForward);
  }

  Future<void> _onLoadRecentTransactions(
    LoadRecentTransactions event,
    Emitter<AdminTraceState> emit,
  ) async {
    emit(AdminTraceLoading());
    try {
      final transactions = await _adminRepository.fetchRecentTransactions();
      emit(AdminTraceLoaded(transactions));
    } catch (e) {
      emit(AdminTraceError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _onTraceTransactionRequested(
    TraceTransactionRequested event,
    Emitter<AdminTraceState> emit,
  ) async {
    if (event.transactionId.trim().isEmpty) {
      add(LoadRecentTransactions());
      return;
    }
    emit(AdminTraceLoading());
    try {
      final transaction = await _adminRepository.traceTransactionById(
        event.transactionId,
      );
      if (transaction != null) {
        emit(AdminTraceLoaded([transaction]));
      } else {
        emit(const AdminTraceError("Transaction ID not found."));
      }
    } catch (e) {
      emit(AdminTraceError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _onTraceParcelForward(
    TraceParcelForward event,
    Emitter<AdminTraceState> emit,
  ) async {
    emit(AdminTraceLoading());
    try {
      final nextTransaction = await _adminRepository
          .findTransactionByInputParcel(event.parcelId);
      if (nextTransaction != null) {
        emit(AdminTraceLoaded([nextTransaction]));
      } else {
        emit(
          const AdminTraceError(
            "This parcel has not been spent yet. The trace ends here.",
          ),
        );
      }
    } catch (e) {
      emit(AdminTraceError(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
