part of 'send_crypto_bloc.dart';

sealed class SendCryptoState extends Equatable {
  const SendCryptoState();
  
  @override
  List<Object> get props => [];
}

final class SendCryptoInitial extends SendCryptoState {}

// The state while the transaction is being processed.
final class SendCryptoInProgress extends SendCryptoState {}

// The state when the transaction is successful.
final class SendCryptoSuccess extends SendCryptoState {
  final String message;
  const SendCryptoSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// The state when the transaction fails.
final class SendCryptoFailure extends SendCryptoState {
  final String error;
  const SendCryptoFailure(this.error);
  @override
  List<Object> get props => [error];
}