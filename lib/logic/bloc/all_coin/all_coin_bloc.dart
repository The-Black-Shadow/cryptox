// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:cryptox/data/models/coin_model.dart';
import 'package:cryptox/data/repositories/allcoin_repository.dart';
import 'package:flutter/rendering.dart';

part 'all_coin_event.dart';
part 'all_coin_state.dart';

class AllCoinBloc extends Bloc<AllCoinEvent, AllCoinState> {
  AllCoinRepository allCoinRepository;
  final List<Coin> _allCoins = [];
  AllCoinBloc(this.allCoinRepository) : super(AllCoinInitial()) {
    on<LoadAllCoins>((event, emit) async {
      emit(AllCoinLoading());
      try {
        final coins = await allCoinRepository.fetchAllCoins();
        debugPrint('All coins loaded: ${coins.length}');
        emit(AllCoinLoaded(coins));
      } catch (e) {
        emit(AllCoinFailure(e.toString()));
      }
    });
    on<SearchCoins>((event, emit) {
      final filtered = _allCoins.where((coin) {
        final query = event.query.toLowerCase();
        return coin.name.toLowerCase().contains(query) ||
            coin.symbol.toLowerCase().contains(query);
      }).toList();

      emit(AllCoinLoaded(filtered));
    });
  }
}
