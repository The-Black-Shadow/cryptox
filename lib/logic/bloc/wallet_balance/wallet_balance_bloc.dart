import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart'; // Import for transformers
import 'package:equatable/equatable.dart';
import '../../../data/models/crypto_balance_model.dart';
import '../../../data/models/coin_display_info.dart';
import '../../../data/repositories/wallet_repository.dart';

part 'wallet_balance_event.dart';
part 'wallet_balance_state.dart';

class WalletBalanceBloc extends Bloc<WalletBalanceEvent, WalletBalanceState> {
  final WalletRepository walletRepository;
  // No need for StreamSubscription if using emit.forEach with a restartable transformer

  WalletBalanceBloc({required this.walletRepository})
    : super(WalletBalanceInitial()) {
    on<LoadWalletBalance>(
      (event, emit) async {
        // Emit loading state before starting to listen to the stream
        emit(WalletBalanceLoading());

        // emit.forEach handles subscription and cancellation automatically
        // when used with a transformer like restartable() or droppable().
        // restartable() ensures that if LoadWalletBalance is dispatched again,
        // the previous stream subscription is cancelled and a new one starts.
        await emit.forEach<CryptoBalance>(
          walletRepository
              .watchCurrentUserCryptoBalance(), // The new stream method
          onData: (cryptoBalance) {
            return WalletBalanceLoaded(
              cryptoBalance: cryptoBalance,
              availableCoins: supportedCoinsDisplayInfo, // Your static list
            );
          },
          onError: (error, stackTrace) {
            print('Error in WalletBalanceBloc stream: $error'); // Log the error
            return WalletBalanceError(
              error.toString().replaceFirst("Exception: ", ""),
            );
          },
        );
      },
      transformer: restartable(),
    ); // Use restartable() to manage the stream subscription lifecycle
  }

  // No explicit close() needed for the subscription if using emit.forEach with a transformer
  // that handles cancellation (like restartable, droppable, sequential).
  // The BLoC's own close method will be handled by the framework.
}
