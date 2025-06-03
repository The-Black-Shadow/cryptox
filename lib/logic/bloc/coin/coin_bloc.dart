// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:cryptox/data/models/coin_model.dart';
import 'package:cryptox/data/repositories/coin_repository.dart';
import 'package:flutter/rendering.dart';

part 'coin_event.dart';
part 'coin_state.dart';

class CoinBloc extends Bloc<CoinEvent, CoinState> {
  CoinRepository coinRepository;
  CoinBloc({required this.coinRepository}) : super(CoinInitial()) {
    on<LoadCoins>((event, emit) async {
      emit(CoinLoading());
      try {
        final coins = await coinRepository.fetchCoins(event.coinIds);
        debugPrint('Coins loaded: ${coins.length}');
        emit(CoinLoaded(coins: coins));
      } catch (e) {
        emit(CoinError(message: e.toString()));
      }
    });
  }
}
