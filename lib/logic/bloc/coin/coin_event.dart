part of 'coin_bloc.dart';

sealed class CoinEvent extends Equatable {
  const CoinEvent();

  @override
  List<Object> get props => [];
}

class LoadCoins extends CoinEvent {
  final List<String> coinIds = [
    'bitcoin',
    'ethereum',
    'binancecoin',
    'ripple',
    'solana',
  ];

  LoadCoins();

  @override
  List<Object> get props => [coinIds];
}
