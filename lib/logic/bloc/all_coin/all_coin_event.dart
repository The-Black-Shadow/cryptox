part of 'all_coin_bloc.dart';

sealed class AllCoinEvent extends Equatable {
  const AllCoinEvent();

  @override
  List<Object> get props => [];
}

class LoadAllCoins extends AllCoinEvent {
  const LoadAllCoins();

  @override
  List<Object> get props => [];
}

class SearchCoins extends AllCoinEvent {
  final String query;
  const SearchCoins(this.query);

  @override
  List<Object> get props => [query];
}
