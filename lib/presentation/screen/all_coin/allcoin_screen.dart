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
      appBar: AppBar(title: const Text('All Coins'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search coins...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AllCoinBloc, AllCoinState>(
              builder: (context, state) {
                // Handle Loading State
                if (state is AllCoinLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Handle Loaded State
                else if (state is AllCoinLoaded) {
                  // Case 1: Master list from API is empty
                  if (state.allCoins.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<AllCoinBloc>().add(const LoadAllCoins()),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 3,
                          ),
                          const Center(
                            child: Text('No coins available. Pull to refresh.'),
                          ),
                        ],
                      ),
                    );
                  }
                  // Case 2: Search query yields no results from a non-empty master list
                  if (state.filteredCoins.isEmpty &&
                      _searchController.text.isNotEmpty) {
                    // This message doesn't need pull-to-refresh for loading *all* coins,
                    // as the user can just change/clear the search.
                    return const Center(
                      child: Text('No coins found matching your search.'),
                    );
                  }
                  // Case 3: Data is available and filtered (or all data if no filter)
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<AllCoinBloc>().add(const LoadAllCoins()),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.filteredCoins.length,
                      itemBuilder: (context, index) {
                        final coin = state.filteredCoins[index];
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
                  );
                }
                // Handle Failure State
                else if (state is AllCoinFailure) {
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<AllCoinBloc>().add(const LoadAllCoins()),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 3,
                        ),
                        Center(
                          child: Text(
                            'Error: ${state.error}\nPull to refresh.',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Handle Initial State (or any other unhandled states)
                // This also covers AllCoinInitial.
                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<AllCoinBloc>().add(const LoadAllCoins()),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(height: MediaQuery.of(context).size.height / 3),
                      const Center(
                        child: Text('Pull to refresh to load coins.'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
