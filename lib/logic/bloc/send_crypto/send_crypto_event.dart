part of 'send_crypto_bloc.dart';

sealed class SendCryptoEvent extends Equatable {
  const SendCryptoEvent();

  @override
  List<Object> get props => [];
}


class SendTetherSubmitted extends SendCryptoEvent {
  final String recipientEmail;
  final double amount;

  const SendTetherSubmitted({
    required this.recipientEmail,
    required this.amount,
  });

  @override
  List<Object> get props => [recipientEmail, amount];
}
class ResetSendCrypto extends SendCryptoEvent {}