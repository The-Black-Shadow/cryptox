part of 'all_coin_bloc.dart';

sealed class AllCoinState extends Equatable {
  const AllCoinState();
  
  @override
  List<Object> get props => [];
}

final class AllCoinInitial extends AllCoinState {}

final class AllCoinLoading extends AllCoinState {}

final class AllCoinLoaded extends AllCoinState {
  final List<Coin> coins;

  const AllCoinLoaded(this.coins);

  @override
  List<Object> get props => [coins];
}

final class AllCoinFailure extends AllCoinState {
  final String error;

  const AllCoinFailure(this.error);

  @override
  List<Object> get props => [error];
}