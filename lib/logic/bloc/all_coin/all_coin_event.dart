part of 'all_coin_bloc.dart';

sealed class AllCoinEvent extends Equatable {
  const AllCoinEvent();

  @override
  List<Object> get props => [];
}

class LoadAllCoins extends AllCoinEvent {
  const LoadAllCoins(); // Keep this const

  @override
  List<Object> get props => [];
}

class SearchCoin extends AllCoinEvent {
  final String query;

  const SearchCoin(this.query);

  @override
  List<Object> get props => [query];
}
