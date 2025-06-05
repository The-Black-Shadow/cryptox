part of 'crypto_convert_bloc.dart';

sealed class CryptoConvertEvent extends Equatable {
  const CryptoConvertEvent();
  @override
  List<Object?> get props => [];
}

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

class ExecuteConversionRequested extends CryptoConvertEvent {
  final String fromCoinFirestoreKey;
  final String toCoinFirestoreKey;
  final double amountFrom;
  // The BLoC will use its stored/re-fetched rates for calculation

  const ExecuteConversionRequested({
    required this.fromCoinFirestoreKey,
    required this.toCoinFirestoreKey,
    required this.amountFrom,
  });

  @override
  List<Object?> get props => [fromCoinFirestoreKey, toCoinFirestoreKey, amountFrom];
}