import 'package:cryptox/logic/bloc/coin/coin_bloc.dart';
// Import what's needed for News
import 'package:cryptox/logic/bloc/news/news_bloc.dart';
import 'package:cryptox/data/repositories/news_repository.dart'; //; // Corrected path
import 'package:cryptox/presentation/screen/news_screen.dart/all_news_screen.dart';

import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.currency_bitcoin,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'CryptoX',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                child: BlocBuilder<CoinBloc, CoinState>(
                  builder: (context, coinState) {
                    if (coinState is CoinLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    } else if (coinState is CoinLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<CoinBloc>().add(LoadCoins());
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              // POPULAR COINS CARD
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Popular Coins',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF667eea),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.push(
                                            Routes.ALL_COIN_ROUTE,
                                          ),
                                          child: const Text(
                                            'See All >',
                                            style: TextStyle(
                                              color: Color(0xFF667eea),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // POPULAR COINS LIST
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: coinState.coins.length > 5
                                          ? 5
                                          : coinState.coins.length,
                                      itemBuilder: (context, index) {
                                        final coin = coinState.coins[index];
                                        final priceChange =
                                            coin.priceChangePercentage24h;
                                        final priceChangeColor =
                                            priceChange >= 0
                                            ? Colors.green
                                            : Colors.red;

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Image.network(
                                                  coin.image,
                                                  width: 40,
                                                  height: 40,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                              color: Colors
                                                                  .grey
                                                                  .shade300,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: const Icon(
                                                          Icons
                                                              .currency_bitcoin,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${coin.symbol.toUpperCase()} ${coin.name}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$${coin.currentPrice.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: priceChangeColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: priceChangeColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // NEWS CARD
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Crypto News',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF667eea),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    BlocProvider<NewsBloc>(
                                      create: (blocContext) =>
                                          NewsBloc(
                                            newsRepository:
                                                RepositoryProvider.of<
                                                  NewsRepository
                                                >(blocContext),
                                          )..add(
                                            const LoadAllNewsArticles(page: 1),
                                          ),
                                      child: const AllNewsView(),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      );
                    }

                    // Fallback for other CoinStates
                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<CoinBloc>().add(LoadCoins()),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          alignment: Alignment.center,
                          child: const Text(
                            'No coin data available, pull to refresh!',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
