import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cryptox/data/models/coin_display_info.dart';
import 'package:cryptox/data/models/coin_model.dart';
import 'package:cryptox/data/repositories/coin_repository.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:equatable/equatable.dart';

part 'crypto_convert_event.dart';
part 'crypto_convert_state.dart';


class CryptoConvertBloc extends Bloc<CryptoConvertEvent, CryptoConvertState> {
  final CoinRepository coinRepository;
  final WalletRepository walletRepository;

  CryptoConvertBloc({
    required this.coinRepository,
    required this.walletRepository,
  }) : super(CryptoConvertInitial()) {
    on<ConversionInputsChanged>(
      _onConversionInputsChanged,
      transformer: restartable(), // Prevents spamming API on fast typing
    );
    on<ExecuteConversionRequested>(_onExecuteConversionRequested);
    on<ResetCryptoConvert>((event, emit) => emit(CryptoConvertInitial()));
  }

  Future<void> _onConversionInputsChanged(
    ConversionInputsChanged event,
    Emitter<CryptoConvertState> emit,
  ) async {
    // Validate inputs before proceeding
    if (event.fromCoinGeckoId == null ||
        event.toCoinGeckoId == null ||
        event.fromCoinGeckoId == event.toCoinGeckoId) {
      emit(CryptoConvertInitial());
      return;
    }

    final double amountFrom = double.tryParse(event.amountString) ?? 0.0;
    if (amountFrom <= 0) {
      emit(CryptoConvertInitial());
      return;
    }

    emit(CryptoConvertEstimatingRate());

    try {
      // Fetch USD prices for both coins in a single API call
      final List<Coin> coinDataList = await coinRepository.fetchCoins([
        event.fromCoinGeckoId!,
        event.toCoinGeckoId!,
      ]);

      final Coin fromCoinData = coinDataList.firstWhere(
        (c) => c.id == event.fromCoinGeckoId,
        orElse: () => throw Exception("Data for 'From Coin' not found."),
      );
      final Coin toCoinData = coinDataList.firstWhere(
        (c) => c.id == event.toCoinGeckoId,
        orElse: () => throw Exception("Data for 'To Coin' not found."),
      );

      final double fromCoinUsdPrice = fromCoinData.currentPrice;
      final double toCoinUsdPrice = toCoinData.currentPrice;

      if (toCoinUsdPrice <= 0) {
        throw Exception("Price for 'To Coin' is invalid for conversion.");
      }

      // Calculate the estimated amount of the destination coin
      final double estimatedAmountTo = (amountFrom * fromCoinUsdPrice) / toCoinUsdPrice;

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
      emit(CryptoConvertRateError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _onExecuteConversionRequested(
    ExecuteConversionRequested event,
    Emitter<CryptoConvertState> emit,
  ) async {
    final currentState = state;
    // Ensure we have valid rate information before proceeding
    if (currentState is! CryptoConvertRateLoaded) {
      emit(const CryptoConvertFailure("Conversion rates not ready. Please try again."));
      return;
    }
    
    // Safety check: Ensure the conversion being executed matches the last loaded rate
    if(currentState.fromCoinGeckoId != event.fromCoinInfo.coinGeckoId ||
       currentState.toCoinGeckoId != event.toCoinInfo.coinGeckoId ||
       currentState.amountFrom != event.amountFrom) {
      emit(const CryptoConvertFailure("Inputs changed. Please wait for new rate estimation."));
      return;
    }


    emit(CryptoConvertProcessing());

    try {
      if (event.toCoinInfo.firestoreKey == 'tether') {
        // --- Path 1: Converting any coin TO traceable Tether ---
        await walletRepository.convertToTether(
          fromCoinKey: event.fromCoinInfo.firestoreKey,
          fromAmount: event.amountFrom,
          tetherToReceive: currentState.estimatedAmountTo,
        );
      } else if (event.fromCoinInfo.firestoreKey == 'tether') {
        // --- Path 2: Converting traceable Tether TO any coin ---
        await walletRepository.convertFromTether(
          tetherAmountToSpend: event.amountFrom,
          toCoinKey: event.toCoinInfo.firestoreKey,
          toCoinAmountToReceive: currentState.estimatedAmountTo,
        );
      } else {
        // This path is now blocked by your UI, but we add a BLoC-level check for safety
        throw Exception("Invalid conversion path. Conversions must involve USDT.");
      }

      emit(const CryptoConvertSuccess("Conversion successful!"));
    } catch (e) {
      emit(CryptoConvertFailure(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}

