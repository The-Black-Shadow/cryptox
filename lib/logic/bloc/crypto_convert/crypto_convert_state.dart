part of 'crypto_convert_bloc.dart';

sealed class CryptoConvertState extends Equatable {
  const CryptoConvertState();
  
  @override
  List<Object> get props => [];
}

/// The initial state, before any user input.
final class CryptoConvertInitial extends CryptoConvertState {}

/// State while fetching exchange rates.
final class CryptoConvertEstimatingRate extends CryptoConvertState {}

/// State when exchange rates are loaded and an estimate is ready.
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

  // --- THIS IS THE FIX ---
  // The 'props' getter must return List<Object>, not List<Object?>.
  @override
  List<Object> get props => [
        fromCoinGeckoId,
        toCoinGeckoId,
        amountFrom,
        fromCoinUsdPrice,
        toCoinUsdPrice,
        estimatedAmountTo,
      ];
}

/// State when fetching exchange rates fails.
final class CryptoConvertRateError extends CryptoConvertState {
  final String message;
  const CryptoConvertRateError(this.message);
  @override
  List<Object> get props => [message];
}

/// State while the conversion transaction is being written to Firestore.
final class CryptoConvertProcessing extends CryptoConvertState {}

/// State when the conversion transaction succeeds.
final class CryptoConvertSuccess extends CryptoConvertState {
  final String message;
  const CryptoConvertSuccess(this.message);
  @override
  List<Object> get props => [message];
}

/// State when the conversion transaction fails.
final class CryptoConvertFailure extends CryptoConvertState {
  final String message;
  const CryptoConvertFailure(this.message);
  @override
  List<Object> get props => [message];
}