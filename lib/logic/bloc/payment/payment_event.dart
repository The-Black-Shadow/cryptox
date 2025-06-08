part of 'payment_bloc.dart';

sealed class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

// Event triggered when the user presses the "Pay" button
class PaymentRequested extends PaymentEvent {
  final String amount;
  final String currency;

  const PaymentRequested({required this.amount, required this.currency});

  @override
  List<Object> get props => [amount, currency];
}
