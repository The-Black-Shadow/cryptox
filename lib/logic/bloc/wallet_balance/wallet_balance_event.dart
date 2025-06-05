part of 'wallet_balance_bloc.dart';

sealed class WalletBalanceEvent extends Equatable {
  const WalletBalanceEvent();
  @override
  List<Object> get props => [];
}

class LoadWalletBalance extends WalletBalanceEvent {}
