part of 'payment_bloc.dart';

sealed class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object> get props => [];
}

final class PaymentInitial extends PaymentState {}

// State when the payment process is in progress
class PaymentLoading extends PaymentState {}

// State when the payment is successful
class PaymentSuccess extends PaymentState {}

// State when the payment has failed
class PaymentFailure extends PaymentState {
  final String error;

  const PaymentFailure({required this.error});

  @override
  List<Object> get props => [error];
}
