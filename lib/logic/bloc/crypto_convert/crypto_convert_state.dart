part of 'crypto_convert_bloc.dart';

sealed class CryptoConvertState extends Equatable {
  const CryptoConvertState();
  @override
  List<Object?> get props => [];
}

final class CryptoConvertInitial extends CryptoConvertState {}

final class CryptoConvertEstimatingRate extends CryptoConvertState {}

final class CryptoConvertRateLoaded extends CryptoConvertState {
  final String fromCoinGeckoId;
  final String toCoinGeckoId;
  final double amountFrom;
  final double fromCoinUsdPrice;
  final double toCoinUsdPrice;
  final double estimatedAmountTo;

  const CryptoConvertRateLoaded({
    required this.fromCoinGeckoId,
    required this.toCoinGeckoId,
    required this.amountFrom,
    required this.fromCoinUsdPrice,
    required this.toCoinUsdPrice,
    required this.estimatedAmountTo,
  });

  @override
  List<Object?> get props => [
        fromCoinGeckoId,
        toCoinGeckoId,
        amountFrom,
        fromCoinUsdPrice,
        toCoinUsdPrice,
        estimatedAmountTo
      ];
}

final class CryptoConvertRateError extends CryptoConvertState {
  final String message;
  const CryptoConvertRateError(this.message);
  @override
  List<Object> get props => [message];
}

final class CryptoConvertProcessing extends CryptoConvertState {}

final class CryptoConvertSuccess extends CryptoConvertState {
  final String message;
  const CryptoConvertSuccess(this.message);
  @override
  List<Object> get props => [message];
}

final class CryptoConvertFailure extends CryptoConvertState {
  final String message;
  const CryptoConvertFailure(this.message);
  @override
  List<Object> get props => [message];
}