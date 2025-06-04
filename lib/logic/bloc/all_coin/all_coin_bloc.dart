// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:cryptox/data/models/coin_model.dart';
import 'package:cryptox/data/repositories/allcoin_repository.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

part 'all_coin_event.dart';
part 'all_coin_state.dart';

class AllCoinBloc extends Bloc<AllCoinEvent, AllCoinState> {
  final AllCoinRepository allCoinRepository;
  String _currentSearchQuery = ""; // Stores the active search query

  AllCoinBloc(this.allCoinRepository) : super(AllCoinInitial()) {
    on<LoadAllCoins>((event, emit) async {
      emit(AllCoinLoading());
      try {
        final coins = await allCoinRepository.fetchAllCoins();
        debugPrint('All coins loaded: ${coins.length}');
        // Apply the current (or empty) search query to the newly loaded coins
        final filteredCoins = _filterCoinsLogic(coins, _currentSearchQuery);
        emit(AllCoinLoaded(allCoins: coins, filteredCoins: filteredCoins));
      } catch (e) {
        emit(AllCoinFailure(e.toString()));
      }
    });

    on<SearchCoin>((event, emit) {
      _currentSearchQuery = event.query; // Update the stored query
      final currentState = state;
      if (currentState is AllCoinLoaded) {
        // Filter the existing master list of coins
        final filteredList = _filterCoinsLogic(currentState.allCoins, _currentSearchQuery);
        emit(AllCoinLoaded(allCoins: currentState.allCoins, filteredCoins: filteredList));
      }
      // If state is not AllCoinLoaded (e.g., still loading or initial),
      // the query is stored and will be applied when LoadAllCoins completes.
    });
  }

  // Helper method for filtering logic
  List<Coin> _filterCoinsLogic(List<Coin> allCoins, String query) {
    final normalizedQuery = query.toLowerCase();
    if (normalizedQuery.isEmpty) {
      return allCoins; // Return all coins if query is empty
    }
    return allCoins.where((coin) {
      return coin.name.toLowerCase().contains(normalizedQuery) ||
             coin.symbol.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
}