import 'package:cryptox/logic/bloc/all_coin/all_coin_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Assuming Coin model might be needed for type hints if not implicitly handled by BLoC states
// import 'package:cryptox/data/models/coin_model.dart';

class AllcoinScreen extends StatefulWidget {
  const AllcoinScreen({super.key});

  @override
  State<AllcoinScreen> createState() => _AllcoinScreenState();
}

class _AllcoinScreenState extends State<AllcoinScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AllCoinBloc>().add(const LoadAllCoins());
    _searchController.addListener(_onSearchQueryChanged);
  }

  void _onSearchQueryChanged() {
    context.read<AllCoinBloc>().add(SearchCoin(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

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
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.currency_bitcoin,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'All Coins',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Search Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.all(20),
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search coins...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF667eea),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Content Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  padding: const EdgeInsets.all(20),
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
                  child: BlocBuilder<AllCoinBloc, AllCoinState>(
                    builder: (context, state) {
                      // Handle Loading State
                      if (state is AllCoinLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF667eea),
                          ),
                        );
                      }
                      // Handle Loaded State
                      else if (state is AllCoinLoaded) {
                        // Case 1: Master list from API is empty
                        if (state.allCoins.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () async => context
                                .read<AllCoinBloc>()
                                .add(const LoadAllCoins()),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: <Widget>[
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 3,
                                ),
                                const Center(
                                  child: Text(
                                    'No coins available. Pull to refresh.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        // Case 2: Search query yields no results from a non-empty master list
                        if (state.filteredCoins.isEmpty &&
                            _searchController.text.isNotEmpty) {
                          return const Center(
                            child: Text(
                              'No coins found matching your search.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        // Case 3: Data is available and filtered (or all data if no filter)
                        return RefreshIndicator(
                          onRefresh: () async => context
                              .read<AllCoinBloc>()
                              .add(const LoadAllCoins()),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.filteredCoins.length,
                            itemBuilder: (context, index) {
                              final coin = state.filteredCoins[index];
                              final priceChange = coin.priceChangePercentage24h;
                              final priceChangeColor = priceChange >= 0
                                  ? Colors.green
                                  : Colors.red;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        coin.image,
                                        width: 50,
                                        height: 50,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade300,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.currency_bitcoin,
                                                    color: Color(0xFF667eea),
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            coin.symbol.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF667eea),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            coin.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${coin.currentPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: priceChangeColor.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
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
                        );
                      }
                      // Handle Failure State
                      else if (state is AllCoinFailure) {
                        return RefreshIndicator(
                          onRefresh: () async => context
                              .read<AllCoinBloc>()
                              .add(const LoadAllCoins()),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 3,
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error: ${state.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Pull to refresh.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      // Handle Initial State (or any other unhandled states)
                      return RefreshIndicator(
                        onRefresh: () async => context.read<AllCoinBloc>().add(
                          const LoadAllCoins(),
                        ),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: <Widget>[
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 3,
                            ),
                            const Center(
                              child: Text(
                                'Pull to refresh to load coins.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
