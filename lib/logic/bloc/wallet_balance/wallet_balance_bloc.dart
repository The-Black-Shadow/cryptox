import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart'; // Import for transformers
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../data/models/crypto_balance_model.dart';
import '../../../data/models/coin_display_info.dart';
import '../../../data/repositories/wallet_repository.dart';

part 'wallet_balance_event.dart';
part 'wallet_balance_state.dart';

class WalletBalanceBloc extends Bloc<WalletBalanceEvent, WalletBalanceState> {
  final WalletRepository walletRepository;

  WalletBalanceBloc({required this.walletRepository})
      : super(WalletBalanceInitial()) {
    // --- Event Handler for Loading/Watching Balances ---
    on<LoadWalletBalance>(
      _onLoadWalletBalance,
      // The restartable() transformer is crucial. If LoadWalletBalance is
      // dispatched again, it cancels the previous stream subscription
      // before starting a new one, preventing memory leaks.
      transformer: restartable(),
    );

    // --- Event Handler for Resetting State on Logout ---
    on<ResetWalletBalance>((event, emit) {
      // When this event is received, simply emit the initial state
      // to clear out any previous user's data.
      emit(WalletBalanceInitial());
    });
  }

  /// This private method handles the logic for the LoadWalletBalance event.
  Future<void> _onLoadWalletBalance(
    LoadWalletBalance event,
    Emitter<WalletBalanceState> emit,
  ) async {
    // Emit a loading state immediately to give feedback to the UI.
    emit(WalletBalanceLoading());

    // Use emit.forEach to listen to the stream from the repository.
    // This automatically handles the stream subscription lifecycle.
    await emit.forEach<CryptoBalance>(
      walletRepository.watchCurrentUserCryptoBalance(),
      onData: (cryptoBalance) {
        // For each new CryptoBalance object from the stream, emit a new Loaded state.
        return WalletBalanceLoaded(
          cryptoBalance: cryptoBalance,
          availableCoins: supportedCoinsDisplayInfo, // Your static list of display info
        );
      },
      onError: (error, stackTrace) {
        // If the stream produces an error, log it and emit an Error state.
        debugPrint('Error in WalletBalanceBloc stream: $error');
        return WalletBalanceError(
          error.toString().replaceFirst("Exception: ", ""),
        );
      },
    );
  }
}

