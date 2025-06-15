import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cryptox/data/models/coin_model.dart';
import 'package:cryptox/data/repositories/coin_repository.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'crypto_convert_event.dart';
part 'crypto_convert_state.dart';

class CryptoConvertBloc extends Bloc<CryptoConvertEvent, CryptoConvertState> {
  final CoinRepository coinRepository;
  final WalletRepository walletRepository;
  final FirebaseAuth _firebaseAuth; // To get current user ID

  CryptoConvertBloc({
    required this.coinRepository,
    required this.walletRepository,
    FirebaseAuth? firebaseAuth, // Optional for testing
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       super(CryptoConvertInitial()) {
    on<ConversionInputsChanged>(
      _onConversionInputsChanged,
      transformer: restartable(),
    );
    on<ExecuteConversionRequested>(_onExecuteConversionRequested);
    on<ResetCryptoConvert>((event, emit) {
      emit(CryptoConvertInitial());
    });
  }

  Future<void> _onConversionInputsChanged(
    ConversionInputsChanged event,
    Emitter<CryptoConvertState> emit,
  ) async {
    if (event.fromCoinGeckoId == null ||
        event.toCoinGeckoId == null ||
        event.fromCoinGeckoId == event.toCoinGeckoId) {
      emit(CryptoConvertInitial()); // Or a specific state like InvalidPair
      return;
    }

    final double amountFrom = double.tryParse(event.amountString) ?? 0.0;
    if (amountFrom <= 0) {
      emit(CryptoConvertInitial()); // Or a specific state like InvalidAmount
      return;
    }

    emit(CryptoConvertEstimatingRate());

    try {
      final List<Coin> coinDataList = await coinRepository.fetchCoins([
        event.fromCoinGeckoId!,
        event.toCoinGeckoId!,
      ]);

      final Coin fromCoinData = coinDataList.firstWhere(
        (c) => c.id == event.fromCoinGeckoId,
        orElse: () => throw Exception("From coin data not found"),
      );
      final Coin toCoinData = coinDataList.firstWhere(
        (c) => c.id == event.toCoinGeckoId,
        orElse: () => throw Exception("To coin data not found"),
      );

      final double fromCoinUsdPrice = fromCoinData.currentPrice;
      final double toCoinUsdPrice = toCoinData.currentPrice;

      if (toCoinUsdPrice == 0) {
        // Avoid division by zero
        throw Exception(
          "Price for 'To Coin' is zero, cannot estimate conversion.",
        );
      }

      final double estimatedAmountTo =
          (amountFrom * fromCoinUsdPrice) / toCoinUsdPrice;

      emit(
        CryptoConvertRateLoaded(
          fromCoinGeckoId: event.fromCoinGeckoId!,
          toCoinGeckoId: event.toCoinGeckoId!,
          amountFrom: amountFrom,
          fromCoinUsdPrice: fromCoinUsdPrice,
          toCoinUsdPrice: toCoinUsdPrice,
          estimatedAmountTo: estimatedAmountTo,
        ),
      );
    } catch (e) {
      emit(
        CryptoConvertRateError(e.toString().replaceFirst("Exception: ", "")),
      );
    }
  }

  Future<void> _onExecuteConversionRequested(
    ExecuteConversionRequested event,
    Emitter<CryptoConvertState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CryptoConvertRateLoaded) {
      emit(
        const CryptoConvertFailure(
          "Conversion rates not loaded. Please try again.",
        ),
      );
      return;
    }

    // Ensure the current loaded rates correspond to the requested conversion (optional safety check)
    // For simplicity, we assume they do if this event is triggered from a UI reflecting CryptoConvertRateLoaded state.

    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      emit(const CryptoConvertFailure("User not authenticated."));
      return;
    }

    emit(CryptoConvertProcessing());

    try {
      // Recalculate amountTo based on the stored rates from CryptoConvertRateLoaded
      // This uses the rates that were last displayed to the user for the estimate.
      final double amountToIncrement =
          (event.amountFrom * currentState.fromCoinUsdPrice) /
          currentState.toCoinUsdPrice;
      // TODO: Implement fee logic here if needed
      // final double fee = 0; // Example: calculate fee
      // final double amountFromAfterFee = event.amountFrom - fee; (if fee from source)
      // final double amountToAfterFee = amountToIncrement - fee; (if fee from destination)

      await walletRepository.performConversionTransaction(
        userId: currentUser.uid,
        fromCoinFirestoreKey: event.fromCoinFirestoreKey,
        amountToDecrement: event.amountFrom, // Decrement by original amount
        toCoinFirestoreKey: event.toCoinFirestoreKey,
        amountToIncrement:
            amountToIncrement, // Increment by calculated amount (after fees if any)
      );
      emit(const CryptoConvertSuccess("Conversion successful!"));
    } catch (e) {
      emit(CryptoConvertFailure(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
