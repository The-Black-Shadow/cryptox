part of 'crypto_convert_bloc.dart';

sealed class CryptoConvertEvent extends Equatable {
  const CryptoConvertEvent();
  @override
  List<Object?> get props => [];
}

/// Dispatched when the user changes the amount or selected coins to get an estimate.
class ConversionInputsChanged extends CryptoConvertEvent {
  final String? fromCoinGeckoId;
  final String? toCoinGeckoId;
  final String amountString;

  const ConversionInputsChanged({
    required this.fromCoinGeckoId,
    required this.toCoinGeckoId,
    required this.amountString,
  });

  @override
  List<Object?> get props => [fromCoinGeckoId, toCoinGeckoId, amountString];
}

/// Dispatched when the user presses the "Convert" button to execute the transaction.
class ExecuteConversionRequested extends CryptoConvertEvent {
  final CoinDisplayInfo fromCoinInfo;
  final CoinDisplayInfo toCoinInfo;
  final double amountFrom;

  const ExecuteConversionRequested({
    required this.fromCoinInfo,
    required this.toCoinInfo,
    required this.amountFrom,
  });

  @override
  List<Object?> get props => [fromCoinInfo, toCoinInfo, amountFrom];
}

/// Dispatched on logout to clear any held state.
class ResetCryptoConvert extends CryptoConvertEvent {}