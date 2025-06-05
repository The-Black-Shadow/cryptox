import 'package:cryptox/logic/bloc/coin/coin_bloc.dart';
// Import what's needed for News
import 'package:cryptox/logic/bloc/news/news_bloc.dart';
import 'package:cryptox/data/repositories/news_repository.dart'; //; // Corrected path
import 'package:cryptox/presentation/screen/news_screen.dart/all_news_screen.dart';
// (Ensure the path to AllNewsView is correct, you might need to adjust the import if AllNewsView is in all_news_screen.dart)

import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CryptoX')),
      body: BlocBuilder<CoinBloc, CoinState>(
        builder: (context, coinState) {
          if (coinState is CoinLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (coinState is CoinLoaded) {
            // Use RefreshIndicator at the top level if you want the whole page to refresh
            return RefreshIndicator(
              onRefresh: () async {
                // Add all refresh actions here
                context.read<CoinBloc>().add(LoadCoins());
                // If NewsBloc is accessible or you manage its instance differently, refresh it too.
                // For now, NewsBloc is created fresh when this part of UI builds.
                // To refresh news on pull, NewsBloc would need to be managed at or above HomeScreen level,
                // or you could use a GlobalKey to access its state's BLoC.
                // A simpler approach if NewsBloc is only used here is it will reload when this view rebuilds after coin load.
              },
              child: ListView(
                // Changed Column to ListView for overall scrollability
                children: [
                  // POPULAR COINS SECTION
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30.0,
                      right: 10.0,
                      top: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Popular Coins',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(Routes.ALL_COIN_ROUTE),
                          child: const Text('See All >'),
                        ),
                      ],
                    ),
                  ),
                  // POPULAR COINS LIST
                  // This ListView.builder is now inside another ListView.
                  // We need to prevent scrolling conflicts and give it a proper height.
                  // Since it's no longer inside an Expanded, we can let it take its content height.
                  ListView.builder(
                    shrinkWrap:
                        true, // Important for ListView inside another scrollable
                    physics:
                        const NeverScrollableScrollPhysics(), // Let parent ListView handle scroll
                    itemCount: coinState.coins.length,
                    itemBuilder: (context, index) {
                      final coin = coinState.coins[index];
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

                  // NEWS SECTION
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      top: 24.0,
                      bottom: 8.0,
                    ),
                    child: Text(
                      'Crypto News',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BlocProvider<NewsBloc>(
                    create: (blocContext) => NewsBloc(
                      newsRepository: RepositoryProvider.of<NewsRepository>(
                        blocContext,
                      ),
                    )..add(const LoadAllNewsArticles(page: 1)),
                    child: const AllNewsView(),
                  ),
                  const SizedBox(
                    height: 24,
                  ), // More spacing at the bottom for scroll aesthetics
                ],
              ),
            );
          }

          // Fallback for other CoinStates (e.g., CoinError, CoinInitial)
          return RefreshIndicator(
            onRefresh: () async => context.read<CoinBloc>().add(LoadCoins()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: Text('No coin data available, pull to refresh!')),
              ],
            ),
          );
        },
      ),
    );
  }
}
