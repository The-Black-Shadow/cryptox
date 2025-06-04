part of 'all_coin_bloc.dart';

sealed class AllCoinState extends Equatable {
  const AllCoinState();

  @override
  List<Object> get props => [];
}

final class AllCoinInitial extends AllCoinState {}

final class AllCoinLoading extends AllCoinState {}

final class AllCoinLoaded extends AllCoinState {
  final List<Coin> allCoins; // Master list of all fetched coins
  final List<Coin> filteredCoins; // List of coins to display (after filtering)

  const AllCoinLoaded({required this.allCoins, required this.filteredCoins});

  @override
  List<Object> get props => [allCoins, filteredCoins];
}

final class AllCoinFailure extends AllCoinState {
  final String error;

  const AllCoinFailure(this.error);

  @override
  List<Object> get props => [error];
}
