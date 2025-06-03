part of 'coin_bloc.dart';

sealed class CoinState extends Equatable {
  const CoinState();

  @override
  List<Object> get props => [];
}

final class CoinInitial extends CoinState {}

final class CoinLoading extends CoinState {}

final class CoinLoaded extends CoinState {
  final List<Coin> coins;

  const CoinLoaded({required this.coins});

  @override
  List<Object> get props => [coins];
}

final class CoinError extends CoinState {
  final String message;

  const CoinError({required this.message});

  @override
  List<Object> get props => [message];
}