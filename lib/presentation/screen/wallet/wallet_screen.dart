import 'package:cryptox/data/models/coin_display_info.dart';
import 'package:cryptox/data/models/crypto_balance_model.dart';
import 'package:cryptox/logic/bloc/crypto_convert/crypto_convert_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/presentation/widgets/wallet_buton.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';// Your WalletButton widget

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String? selectedCoinName;
  String? _fromCoinDisplayName; // Store displayName for UI
  String? _toCoinDisplayName;   // Store displayName for UI

  final TextEditingController amountController = TextEditingController();
  final TextEditingController estimatedController = TextEditingController();

  // Debouncer for amount input to avoid too many API calls
  late final Debouncer<String> _amountDebouncer;

  // To store currently loaded rate information
  CryptoConvertRateLoaded? _currentRateInfo;


  @override
  void initState() {
    super.initState();
    // Initialize debouncer (e.g., 500ms delay)
    _amountDebouncer = Debouncer(const Duration(milliseconds: 700), initialValue: '');
    _amountDebouncer.values.listen((amountString) {
      _triggerRateEstimation();
    });

    amountController.addListener(() {
      _amountDebouncer.value = amountController.text;
    });
  }

  void _triggerRateEstimation() {
    if (_fromCoinDisplayName != null && _toCoinDisplayName != null && amountController.text.isNotEmpty) {
      final fromCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _fromCoinDisplayName);
      final toCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _toCoinDisplayName);
      context.read<CryptoConvertBloc>().add(ConversionInputsChanged(
            fromCoinGeckoId: fromCoinInfo.coinGeckoId,
            toCoinGeckoId: toCoinInfo.coinGeckoId,
            amountString: amountController.text,
          ));
    } else {
       // Clear estimate if inputs are not valid
       if (mounted) {
        setState(() {
          estimatedController.text = '';
          _currentRateInfo = null; // Clear stored rate info
        });
         context.read<CryptoConvertBloc>().add(ConversionInputsChanged(fromCoinGeckoId: null, toCoinGeckoId: null, amountString: '0')); // Reset BLoC
       }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    estimatedController.dispose();
    super.dispose();
  }

  double _getBalanceForFirestoreKey(CryptoBalance balances, String firestoreKey) {
    // ... (your existing helper method)
    switch (firestoreKey) {
      case 'bitcoin': return balances.bitcoin;
      case 'ethereum': return balances.ethereum;
      case 'bnb': return balances.bnb;
      case 'x': return balances.x;
      default: return 0.0;
    }
  }

  void _handleConvertPressed() {
    final walletState = context.read<WalletBalanceBloc>().state;
    final convertState = context.read<CryptoConvertBloc>().state;

    if (_fromCoinDisplayName == null || _toCoinDisplayName == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select coins and enter amount.")));
      return;
    }

    if (walletState is! WalletBalanceLoaded) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wallet balances not loaded.")));
      return;
    }
     if (convertState is! CryptoConvertRateLoaded) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conversion rate not available. Please wait or try again.")));
      return;
    }


    final fromCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _fromCoinDisplayName);
    final toCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _toCoinDisplayName);

    final double amountFrom = double.tryParse(amountController.text) ?? 0.0;
    if (amountFrom <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount.")));
      return;
    }

    final double currentFromBalance = _getBalanceForFirestoreKey(walletState.cryptoBalance, fromCoinInfo.firestoreKey);
    if (currentFromBalance < amountFrom) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insufficient ${fromCoinInfo.displayName} balance.")));
      return;
    }

    // Use the rates from the loaded state
    // This check might be redundant if _currentRateInfo is correctly updated by BlocListener
    if (_currentRateInfo == null || 
        _currentRateInfo!.fromCoinGeckoId != fromCoinInfo.coinGeckoId ||
        _currentRateInfo!.toCoinGeckoId != toCoinInfo.coinGeckoId ||
        _currentRateInfo!.amountFrom != amountFrom) {
          // This condition implies the displayed estimate might not match current inputs,
          // possibly due to ongoing rate estimation or an error.
          // For simplicity, we proceed if _currentRateInfo has *some* values that were used for the last estimate.
          // A more robust UI would disable the convert button until estimate is ready and matches current input.
         if (convertState.fromCoinGeckoId != fromCoinInfo.coinGeckoId ||
             convertState.toCoinGeckoId != toCoinInfo.coinGeckoId ||
             convertState.amountFrom != amountFrom) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rate information is outdated or not ready. Please wait for estimation.")));
              return;
             }
    }


    context.read<CryptoConvertBloc>().add(ExecuteConversionRequested(
          fromCoinFirestoreKey: fromCoinInfo.firestoreKey,
          toCoinFirestoreKey: toCoinInfo.firestoreKey,
          amountFrom: amountFrom,
        ));
  }


  @override
  Widget build(BuildContext context) {
    // WalletScreen should now be wrapped in MultiBlocProvider or ensure both blocs are available
    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet"), centerTitle: true),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WalletBalanceBloc, WalletBalanceState>(
            listener: (context, state) {
              if (state is WalletBalanceLoaded) {
                if (mounted) { // Ensure widget is still in the tree
                  setState(() {
                    if (selectedCoinName == null && state.availableCoins.isNotEmpty) {
                      selectedCoinName = state.availableCoins.first.displayName;
                    }
                    if (_fromCoinDisplayName == null && state.availableCoins.isNotEmpty) {
                      _fromCoinDisplayName = state.availableCoins.first.displayName;
                    }
                    if (_toCoinDisplayName == null && state.availableCoins.length > 1) {
                      _toCoinDisplayName = state.availableCoins[1].displayName;
                    } else if (_toCoinDisplayName == null && state.availableCoins.isNotEmpty) {
                      _toCoinDisplayName = state.availableCoins.first.displayName;
                    }
                     _triggerRateEstimation(); // Trigger estimation when coins are initialized
                  });
                }
              } else if (state is WalletBalanceError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet Error: ${state.message}')));
              }
            },
          ),
          BlocListener<CryptoConvertBloc, CryptoConvertState>(
            listener: (context, state) {
              if (state is CryptoConvertRateLoaded) {
                if (mounted) {
                  setState(() {
                    // Only update if the loaded rate is for the current input amount
                    // This prevents stale estimates if user types fast after a rate loads
                    if (state.amountFrom == (double.tryParse(amountController.text) ?? 0.0) &&
                        state.fromCoinGeckoId == supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _fromCoinDisplayName, orElse: () => supportedCoinsDisplayInfo.first).coinGeckoId &&
                        state.toCoinGeckoId == supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _toCoinDisplayName, orElse: () => supportedCoinsDisplayInfo.first).coinGeckoId
                    ) {
                        estimatedController.text = "${state.estimatedAmountTo.toStringAsFixed(8)} ${_toCoinDisplayName != null ? supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _toCoinDisplayName).symbol : ''}";
                        _currentRateInfo = state; // Store current rate info
                    }
                  });
                }
              } else if (state is CryptoConvertEstimatingRate) {
                 if (mounted) {
                    setState(() {
                      estimatedController.text = 'Estimating...';
                      _currentRateInfo = null;
                    });
                 }
              } else if (state is CryptoConvertRateError) {
                 if (mounted) {
                    setState(() {
                      estimatedController.text = 'Error fetching rate';
                       _currentRateInfo = null;
                    });
                 }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rate Error: ${state.message}')));
              } else if (state is CryptoConvertSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green,));
                amountController.clear();
                estimatedController.clear();
                _currentRateInfo = null;
                context.read<WalletBalanceBloc>().add(LoadWalletBalance()); // Refresh wallet balance
                context.read<CryptoConvertBloc>().add(ConversionInputsChanged(fromCoinGeckoId: null, toCoinGeckoId: null, amountString: '0')); // Reset convert bloc
              } else if (state is CryptoConvertFailure) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conversion Failed: ${state.message}'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
        child: BlocBuilder<WalletBalanceBloc, WalletBalanceState>(
          builder: (context, walletState) {
            if (walletState is WalletBalanceLoading || walletState is WalletBalanceInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (walletState is WalletBalanceLoaded) {
              final CoinDisplayInfo? currentSelectedCoinInfo = selectedCoinName != null
                  ? walletState.availableCoins.firstWhere((c) => c.displayName == selectedCoinName, orElse: () => walletState.availableCoins.first)
                  : (walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first : null);
              final double selectedBalanceAmount = currentSelectedCoinInfo != null
                  ? _getBalanceForFirestoreKey(walletState.cryptoBalance, currentSelectedCoinInfo.firestoreKey)
                  : 0.0;
              final String selectedFormattedBalance = currentSelectedCoinInfo != null
                  ? '${selectedBalanceAmount.toStringAsFixed(6)} ${currentSelectedCoinInfo.symbol}'
                  : '0.00';

              return Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row( /* ... Send/Deposit Buttons ... */ 
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          WalletButton(label: "Send", icon: Icons.send, onPressed: () { /* ... */ }),
                          WalletButton(label: 'Deposit', icon: Icons.file_download_outlined, onPressed: () { /* ... */ }),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Balance Display Section
                      const Text("All Crypto Balance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        value: selectedCoinName ?? (walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first.displayName : null),
                        items: walletState.availableCoins.map((coinInfo) => coinInfo.displayName).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedCoinName = value);
                            // No need to trigger rate estimation here unless it's tied to this dropdown
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Container( /* ... Balance display container ... */ 
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedCoinName ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(selectedFormattedBalance, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ),
                      const SizedBox(height: 30),

                      // Convert Section
                      const Text("Convert Coins", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdownField(
                              label: "From Coin",
                              value: _fromCoinDisplayName ?? (walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first.displayName : null),
                              availableCoins: walletState.availableCoins,
                              onChanged: (val) {
                                if (val != null) setState(() => _fromCoinDisplayName = val);
                                _triggerRateEstimation();
                              },
                            ),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.swap_horiz, size: 30)), // Changed Icon
                          Expanded(
                            child: _dropdownField(
                              label: "To Coin",
                              value: _toCoinDisplayName ?? (walletState.availableCoins.length > 1 ? walletState.availableCoins[1].displayName : (walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first.displayName : null)),
                              availableCoins: walletState.availableCoins,
                              onChanged: (val) {
                                if (val != null) setState(() => _toCoinDisplayName = val);
                                _triggerRateEstimation();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController, // Listener already attached in initState
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: "Amount to Convert", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                      ),
                      const SizedBox(height: 12),
                       BlocBuilder<CryptoConvertBloc, CryptoConvertState>( // To show loading for estimate
                         builder: (context, convertState) {
                           Widget estimateSuffix = const SizedBox.shrink();
                           if(convertState is CryptoConvertEstimatingRate){
                             estimateSuffix = const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2,)));
                           }
                           return TextField(
                            controller: estimatedController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "You will receive (approx.)",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              suffixIcon: estimateSuffix,
                              ),
                           );
                         },
                       ),
                      const SizedBox(height: 20),
                      BlocBuilder<CryptoConvertBloc, CryptoConvertState>( // To disable button during processing
                        builder: (context, convertState) {
                          return ElevatedButton(
                            onPressed: (convertState is CryptoConvertProcessing || convertState is CryptoConvertEstimatingRate) ? null : _handleConvertPressed,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Center(child: (convertState is CryptoConvertProcessing) 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                              : const Text("Convert", style: TextStyle(fontSize: 16))),
                          );
                        },
                      ),
                       const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text(walletState is WalletBalanceError ? walletState.message : 'An unknown error occurred.'));
          },
        ),
      ),
    );
  }

  Widget _buildDropdown({ required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    // ... (your existing helper method, ensure items list is not empty if value requires it)
     if (items.isEmpty && value != null) { // Defensive: if items are empty, value should be null
        value = null;
      } else if (items.isNotEmpty && (value == null || !items.contains(value))) {
        value = items.first; // Default to first if value is invalid or null
      }

     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Reduced vertical padding
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            items: items.map((itemValue) => DropdownMenuItem(value: itemValue, child: Text(itemValue, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
            itemHeight: 48, // Ensure items are not too tall
          ),
        ),
      );
  }

  Widget _dropdownField({ required String label, required String? value, required List<CoinDisplayInfo> availableCoins, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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