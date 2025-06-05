import 'package:cryptox/data/models/coin_display_info.dart';
import 'package:cryptox/data/models/crypto_balance_model.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';// Import CryptoBalance if needed directly

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // These will now be driven by BLoC state or derived from it
  String? selectedCoinName; // Store the displayName
  String? fromCoinName;
  String? toCoinName;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController estimatedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Dispatch event to load balance when the screen is initialized
    // Assuming WalletBalanceBloc is provided above this widget in the tree
    // context.read<WalletBalanceBloc>().add(LoadWalletBalance());
    // If providing bloc here, it will be done in build method via BlocProvider
  }

  @override
  void dispose() {
    amountController.dispose();
    estimatedController.dispose();
    super.dispose();
  }

  // Helper to get balance from CryptoBalance object based on firestoreKey
  double _getBalanceForFirestoreKey(CryptoBalance balances, String firestoreKey) {
    switch (firestoreKey) {
      case 'bitcoin':
        return balances.bitcoin;
      case 'ethereum':
        return balances.ethereum;
      case 'bnb':
        return balances.bnb;
      case 'x':
        return balances.x;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet"), centerTitle: true),
      body: BlocConsumer<WalletBalanceBloc, WalletBalanceState>(
        listener: (context, state) {
          if (state is WalletBalanceLoaded) {
            // Initialize dropdown values if they are null and data is loaded
            if (selectedCoinName == null && state.availableCoins.isNotEmpty) {
              selectedCoinName = state.availableCoins.first.displayName;
            }
            if (fromCoinName == null && state.availableCoins.isNotEmpty) {
              fromCoinName = state.availableCoins.first.displayName;
            }
            if (toCoinName == null && state.availableCoins.length > 1) {
              toCoinName = state.availableCoins[1].displayName;
            } else if (toCoinName == null && state.availableCoins.isNotEmpty) {
              toCoinName = state.availableCoins.first.displayName;
            }
          } else if (state is WalletBalanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is WalletBalanceLoading || state is WalletBalanceInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WalletBalanceLoaded) {
            // Find the selected coin's display info to get its symbol and firestore key
            final CoinDisplayInfo? currentSelectedCoinInfo = selectedCoinName != null
                ? state.availableCoins.firstWhere((c) => c.displayName == selectedCoinName, orElse: () => state.availableCoins.first)
                : (state.availableCoins.isNotEmpty ? state.availableCoins.first : null);

            final double selectedBalanceAmount = currentSelectedCoinInfo != null
                ? _getBalanceForFirestoreKey(state.cryptoBalance, currentSelectedCoinInfo.firestoreKey)
                : 0.0;
            
            final String selectedFormattedBalance = currentSelectedCoinInfo != null
                ? '${selectedBalanceAmount.toStringAsFixed(6)} ${currentSelectedCoinInfo.symbol}' // Adjust precision
                : '0.00';


            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _walletButton("Send", Icons.send),
                        _walletButton("Deposit", Icons.download),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Select Coin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          value: selectedCoinName ?? (state.availableCoins.isNotEmpty ? state.availableCoins.first.displayName : null),
                          items: state.availableCoins.map((coinInfo) => coinInfo.displayName).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedCoinName = value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedCoinName ?? 'N/A',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                selectedFormattedBalance,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Convert Coins", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dropdownField(
                                context: context, // Pass context
                                label: "From Coin",
                                value: fromCoinName ?? (state.availableCoins.isNotEmpty ? state.availableCoins.first.displayName : null),
                                availableCoins: state.availableCoins,
                                onChanged: (val) => setState(() => fromCoinName = val),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.arrow_forward, size: 30),
                            ),
                            Expanded(
                              child: _dropdownField(
                                context: context, // Pass context
                                label: "To Coin",
                                value: toCoinName ?? (state.availableCoins.length > 1 ? state.availableCoins[1].displayName : (state.availableCoins.isNotEmpty ? state.availableCoins.first.displayName : null)),
                                availableCoins: state.availableCoins,
                                onChanged: (val) => setState(() => toCoinName = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Amount",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: estimatedController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Estimated",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Placeholder for conversion logic
                            // You'll need actual conversion rates here
                            setState(() {
                              estimatedController.text = "${amountController.text} ${fromCoinName ?? ''} (converted to ${toCoinName ?? ''})";
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Center(child: Text("Convert", style: TextStyle(fontSize: 16))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          // Fallback for WalletBalanceError state (already handled by listener, but can show UI too)
          return Center(child: Text(state is WalletBalanceError ? state.message : 'An unknown error occurred.'));
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          items: items.map((itemValue) {
            return DropdownMenuItem(value: itemValue, child: Text(itemValue));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _walletButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () { /* Handle Send or Deposit */ },
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _dropdownField({
    required BuildContext context, // Add context
    required String label,
    required String? value, // Make value nullable
    required List<CoinDisplayInfo> availableCoins, // Pass CoinDisplayInfo list
    required Function(String?) onChanged, // Allow String? for onChanged
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        _buildDropdown(
          value: value,
          items: availableCoins.map((coinInfo) => coinInfo.displayName).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}