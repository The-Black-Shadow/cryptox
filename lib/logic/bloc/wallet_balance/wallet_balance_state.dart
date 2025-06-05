part of 'wallet_balance_bloc.dart';

sealed class WalletBalanceState extends Equatable {
  const WalletBalanceState();
  @override
  List<Object> get props => [];
}

final class WalletBalanceInitial extends WalletBalanceState {}

final class WalletBalanceLoading extends WalletBalanceState {}

final class WalletBalanceLoaded extends WalletBalanceState {
  final CryptoBalance cryptoBalance;
  final List<CoinDisplayInfo> availableCoins; // To populate dropdowns

  const WalletBalanceLoaded({
    required this.cryptoBalance,
    required this.availableCoins,
  });

  @override
  List<Object> get props => [cryptoBalance, availableCoins];
}

final class WalletBalanceError extends WalletBalanceState {
  final String message;
  const WalletBalanceError(this.message);
  @override
  List<Object> get props => [message];
}
