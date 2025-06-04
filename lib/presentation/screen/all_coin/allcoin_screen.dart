import 'package:cryptox/data/models/coin_model.dart';
import 'package:cryptox/logic/bloc/all_coin/all_coin_bloc.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AllcoinScreen extends StatefulWidget {
  const AllcoinScreen({super.key});

  @override
  State<AllcoinScreen> createState() => _AllcoinScreenState();
}

class _AllcoinScreenState extends State<AllcoinScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Coin> _filteredCoins = [];

  @override
  void initState() {
    super.initState();
    context.read<AllCoinBloc>().add(LoadAllCoins());

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Coin> _filterCoins(List<Coin> allCoins) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return allCoins;
    return allCoins.where((coin) {
      return coin.name.toLowerCase().contains(query) ||
          coin.symbol.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Coins'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(Routes.HOME_ROUTE),
          ),
        ],
      ),
      body: BlocBuilder<AllCoinBloc, AllCoinState>(
        builder: (context, state) {
          if (state is AllCoinLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AllCoinLoaded) {
            _filteredCoins = _filterCoins(state.coins);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search coins...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        context.read<AllCoinBloc>().add(LoadAllCoins()),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredCoins.length,
                      itemBuilder: (context, index) {
                        final coin = _filteredCoins[index];
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
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AllCoinBloc>().add(LoadAllCoins()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(child: Text('No data available, try again later!')),
              ],
            ),
          );
        },
      ),
    );
  }
}
