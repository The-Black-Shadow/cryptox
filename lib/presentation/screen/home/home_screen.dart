import 'package:cryptox/logic/bloc/coin/coin_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CryptoX')),
      body: BlocBuilder<CoinBloc, CoinState>(
        builder: (context, state) {
          if (state is CoinLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CoinLoaded) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 30.0, right: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(onPressed: () => {}, child: Text('See All >')),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        context.read<CoinBloc>().add(LoadCoins()),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.coins.length,
                      itemBuilder: (context, index) {
                        final coin = state.coins[index];
                        final priceChange = coin.priceChangePercentage24h;
                        final priceChangeColor = priceChange >= 0
                            ? Colors.green
                            : Colors.red;

                        return ListTile(
                          leading: Image.network(coin.image, width: 40),
                          title: Text(
                            '${coin.symbol.toUpperCase()} ${coin.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '\$${coin.currentPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: Text(
                            '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 16,
                              color: priceChangeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // const Padding(
                //   padding: EdgeInsets.all(8.0),
                //   child: Text(
                //     '⬇️ Pull to refresh',
                //     style: TextStyle(fontSize: 14, color: Colors.grey),
                //   ),
                // ),
              ],
            );
          }

          return const Center(
            child: Text('No data available, try again later!'),
          );
        },
      ),
    );
  }
}
