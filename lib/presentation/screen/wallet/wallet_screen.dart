import 'package:cryptox/data/models/coin_display_info.dart';
import 'package:cryptox/data/models/crypto_balance_model.dart';
import 'package:cryptox/logic/bloc/crypto_convert/crypto_convert_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/presentation/widgets/wallet_buton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:debounce_throttle/debounce_throttle.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String? selectedCoinName;
  String? _fromCoinDisplayName;
  String? _toCoinDisplayName;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController estimatedController = TextEditingController();

  late final Debouncer<String> _amountDebouncer;
  CryptoConvertRateLoaded? _currentRateInfo;

  @override
  void initState() {
    super.initState();
    _amountDebouncer = Debouncer(const Duration(milliseconds: 700), initialValue: '');
    _amountDebouncer.values.listen((amountString) {
      if (mounted) _triggerRateEstimation();
    });
    amountController.addListener(() {
      if (mounted) _amountDebouncer.value = amountController.text;
    });
  }

  void _triggerRateEstimation() {
    if (!mounted) return;

    bool canCurrentlyConvert = _fromCoinDisplayName != null &&
        _toCoinDisplayName != null &&
        _fromCoinDisplayName != _toCoinDisplayName &&
        amountController.text.isNotEmpty &&
        (double.tryParse(amountController.text) ?? 0.0) > 0;

    if (canCurrentlyConvert) {
      final fromCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _fromCoinDisplayName);
      final toCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _toCoinDisplayName);
      context.read<CryptoConvertBloc>().add(ConversionInputsChanged(
            fromCoinGeckoId: fromCoinInfo.coinGeckoId,
            toCoinGeckoId: toCoinInfo.coinGeckoId,
            amountString: amountController.text,
          ));
    } else {
      setState(() {
        estimatedController.text = '';
        _currentRateInfo = null;
      });
      if (context.read<CryptoConvertBloc>().state is! CryptoConvertInitial &&
          context.read<CryptoConvertBloc>().state is! CryptoConvertEstimatingRate) {
           context.read<CryptoConvertBloc>().add(const ConversionInputsChanged(fromCoinGeckoId: null, toCoinGeckoId: null, amountString: '0'));
      }
    }
  }

  @override
  void dispose() {
    amountController.removeListener(() { if(mounted) _amountDebouncer.value = amountController.text; });
    amountController.dispose();
    estimatedController.dispose();
    super.dispose();
  }

  double _getBalanceForFirestoreKey(CryptoBalance balances, String firestoreKey) {
    switch (firestoreKey) {
      case 'bitcoin': return balances.bitcoin;
      case 'ethereum': return balances.ethereum;
      case 'bnb': return balances.bnb;
      case 'x': return balances.x;
      default: return 0.0;
    }
  }

  void _handleConvertPressed() {
    // ... (keep your existing _handleConvertPressed logic, it already checks if from and to are same) ...
    if (!mounted) return;

    final walletState = context.read<WalletBalanceBloc>().state;
    final convertBloc = context.read<CryptoConvertBloc>();
    final currentConvertState = convertBloc.state;

    if (_fromCoinDisplayName == null || _toCoinDisplayName == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select coins and enter amount.")));
      return;
    }
    if (_fromCoinDisplayName == _toCoinDisplayName) { // Critical check
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot convert a coin to itself.")));
      return;
    }
    // ... (rest of _handleConvertPressed logic from previous version)
    if (walletState is! WalletBalanceLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wallet balances not loaded.")));
      return;
    }
     if (_currentRateInfo == null && currentConvertState is! CryptoConvertRateLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conversion rate not available. Please wait or adjust amount.")));
        return;
    }

    final fromCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _fromCoinDisplayName);
    final toCoinInfo = supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _toCoinDisplayName);
    final double amountFrom = double.tryParse(amountController.text) ?? 0.0;

    if (amountFrom <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid positive amount.")));
      return;
    }
    final double currentFromBalance = _getBalanceForFirestoreKey(walletState.cryptoBalance, fromCoinInfo.firestoreKey);
    if (currentFromBalance < amountFrom) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insufficient ${fromCoinInfo.displayName} balance.")));
      return;
    }

    if (_currentRateInfo != null &&
        (_currentRateInfo!.fromCoinGeckoId != fromCoinInfo.coinGeckoId ||
         _currentRateInfo!.toCoinGeckoId != toCoinInfo.coinGeckoId ||
         _currentRateInfo!.amountFrom != amountFrom)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rate information is outdated for the current input. Please wait for re-estimation or try again.")));
        _triggerRateEstimation();
        return;
    }
     if (_currentRateInfo == null && currentConvertState is CryptoConvertRateLoaded &&
        (currentConvertState.fromCoinGeckoId != fromCoinInfo.coinGeckoId ||
         currentConvertState.toCoinGeckoId != toCoinInfo.coinGeckoId ||
         currentConvertState.amountFrom != amountFrom)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rate information seems stale. Please try again.")));
            _triggerRateEstimation();
            return;
         }

    convertBloc.add(ExecuteConversionRequested(
      fromCoinFirestoreKey: fromCoinInfo.firestoreKey,
      toCoinFirestoreKey: toCoinInfo.firestoreKey,
      amountFrom: amountFrom,
    ));
  }

  void _initializeDropdownSelections(List<CoinDisplayInfo> availableCoins) {
    if (!mounted) return;
    setState(() {
      bool needsEstimateTrigger = false;

      if (selectedCoinName == null && availableCoins.isNotEmpty) {
        selectedCoinName = availableCoins.first.displayName;
      }

      if (_fromCoinDisplayName == null && availableCoins.isNotEmpty) {
        _fromCoinDisplayName = availableCoins.first.displayName;
        needsEstimateTrigger = true;
      }

      if ((_toCoinDisplayName == null || (_fromCoinDisplayName == _toCoinDisplayName)) && availableCoins.isNotEmpty) {
        CoinDisplayInfo? newToCoin;
        if (availableCoins.length > 1) {
          newToCoin = availableCoins.firstWhere(
            (coin) => coin.displayName != _fromCoinDisplayName,
            orElse: () => availableCoins.firstWhere((coin) => coin.displayName == _fromCoinDisplayName) // Should not happen if length > 1 and distinct
          );
        } else { // Only one coin type available
          newToCoin = availableCoins.first;
        }
        _toCoinDisplayName = newToCoin.displayName;
        needsEstimateTrigger = true;
      }

      if (needsEstimateTrigger) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _triggerRateEstimation();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet"), centerTitle: true),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WalletBalanceBloc, WalletBalanceState>(
            listener: (context, state) {
              if (state is WalletBalanceLoaded) {
                _initializeDropdownSelections(state.availableCoins);
              } else if (state is WalletBalanceError) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet Error: ${state.message}')));
              }
            },
          ),
          BlocListener<CryptoConvertBloc, CryptoConvertState>(
            listener: (context, state) {
              if (!mounted) return;
               if (state is CryptoConvertRateLoaded) {
                  final currentAmountFromInput = double.tryParse(amountController.text) ?? -1.0;
                  final fromCoinInfo = _fromCoinDisplayName != null ? supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _fromCoinDisplayName) : null;
                  final toCoinInfo = _toCoinDisplayName != null ? supportedCoinsDisplayInfo.firstWhere((c) => c.displayName == _toCoinDisplayName) : null;

                  if (fromCoinInfo != null && toCoinInfo != null &&
                      state.amountFrom == currentAmountFromInput &&
                      state.fromCoinGeckoId == fromCoinInfo.coinGeckoId &&
                      state.toCoinGeckoId == toCoinInfo.coinGeckoId) {
                    setState(() {
                        estimatedController.text = "${state.estimatedAmountTo.toStringAsFixed(8)} ${toCoinInfo.symbol}";
                        _currentRateInfo = state;
                    });
                  } else if (currentAmountFromInput <= 0 || _fromCoinDisplayName == _toCoinDisplayName) {
                     setState(() { estimatedController.text = ''; _currentRateInfo = null; });
                  }
              } else if (state is CryptoConvertEstimatingRate) {
                setState(() { estimatedController.text = 'Estimating...'; _currentRateInfo = null; });
              } else if (state is CryptoConvertRateError) {
                setState(() { estimatedController.text = 'Error fetching rate'; _currentRateInfo = null; });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rate Error: ${state.message}')));
              } else if (state is CryptoConvertSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
                amountController.clear();
                 _currentRateInfo = null;
                context.read<WalletBalanceBloc>().add(LoadWalletBalance());
                context.read<CryptoConvertBloc>().add(const ConversionInputsChanged(fromCoinGeckoId: null, toCoinGeckoId: null, amountString: '0'));
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
                  ? walletState.availableCoins.firstWhere((c) => c.displayName == selectedCoinName, orElse: () => walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first : supportedCoinsDisplayInfo.first)
                  : (walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first : null);
              final double selectedBalanceAmount = currentSelectedCoinInfo != null
                  ? _getBalanceForFirestoreKey(walletState.cryptoBalance, currentSelectedCoinInfo.firestoreKey)
                  : 0.0;
              final String selectedFormattedBalance = currentSelectedCoinInfo != null
                  ? '${selectedBalanceAmount.toStringAsFixed(6)} ${currentSelectedCoinInfo.symbol}'
                  : '0.00';

              // Generate filtered lists for dropdowns
              List<String> fromCoinItems = walletState.availableCoins
                  .where((coin) => _toCoinDisplayName == null || coin.displayName != _toCoinDisplayName || walletState.availableCoins.length == 1)
                  .map((info) => info.displayName)
                  .toList();
              if (fromCoinItems.isEmpty && walletState.availableCoins.isNotEmpty && _toCoinDisplayName != null) {
                  // This case means the only available coin is the one selected in "To Coin"
                  fromCoinItems = [_toCoinDisplayName!];
              }


              List<String> toCoinItems = walletState.availableCoins
                  .where((coin) => _fromCoinDisplayName == null || coin.displayName != _fromCoinDisplayName || walletState.availableCoins.length == 1)
                  .map((info) => info.displayName)
                  .toList();
               if (toCoinItems.isEmpty && walletState.availableCoins.isNotEmpty && _fromCoinDisplayName != null) {
                  toCoinItems = [_fromCoinDisplayName!];
              }

              // Determine if conversion is possible for UI elements
              bool canAttemptConvert = _fromCoinDisplayName != null &&
                                     _toCoinDisplayName != null &&
                                     _fromCoinDisplayName != _toCoinDisplayName &&
                                     (double.tryParse(amountController.text) ?? 0.0) > 0;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          WalletButton(label: "Send", icon: Icons.send, onPressed: () {}),
                          WalletButton(label: 'Deposit', icon: Icons.file_download_outlined, onPressed: () {}),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text("All Crypto Balance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        value: selectedCoinName,
                        items: walletState.availableCoins.map((coinInfo) => coinInfo.displayName).toList(),
                        onChanged: (value) {
                          if (value != null && mounted) setState(() => selectedCoinName = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Container(
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
                      const Text("Convert Coins", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdownField(
                              label: "From Coin",
                              value: _fromCoinDisplayName,
                              // Pass dynamically filtered items for "From Coin"
                              items: fromCoinItems,
                              onChanged: (val) {
                                if (val != null && mounted) {
                                  setState(() {
                                    _fromCoinDisplayName = val;
                                    if (_fromCoinDisplayName == _toCoinDisplayName && _toCoinDisplayName != null) {
                                      CoinDisplayInfo? newToCoin = walletState.availableCoins.firstWhere(
                                          (coin) => coin.displayName != _fromCoinDisplayName,
                                          orElse: () => walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first : supportedCoinsDisplayInfo.first // Fallback
                                      );
                                      _toCoinDisplayName = newToCoin.displayName;
                                    }
                                  });
                                  _triggerRateEstimation();
                                }
                              },
                            ),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.swap_horiz, size: 30)),
                          Expanded(
                            child: _dropdownField(
                              label: "To Coin",
                              value: _toCoinDisplayName,
                              // Pass dynamically filtered items for "To Coin"
                              items: toCoinItems,
                              onChanged: (val) {
                                if (val != null && mounted) {
                                  setState(() {
                                    _toCoinDisplayName = val;
                                    if (_toCoinDisplayName == _fromCoinDisplayName && _fromCoinDisplayName != null) {
                                       CoinDisplayInfo? newFromCoin = walletState.availableCoins.firstWhere(
                                          (coin) => coin.displayName != _toCoinDisplayName,
                                          orElse: () => walletState.availableCoins.isNotEmpty ? walletState.availableCoins.first : supportedCoinsDisplayInfo.first // Fallback
                                      );
                                      _fromCoinDisplayName = newFromCoin.displayName;
                                    }
                                  });
                                  _triggerRateEstimation();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: "Amount to Convert", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                      ),
                      const SizedBox(height: 12),
                       BlocBuilder<CryptoConvertBloc, CryptoConvertState>(
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
                      BlocBuilder<CryptoConvertBloc, CryptoConvertState>(
                        builder: (context, convertState) {
                          bool isProcessing = convertState is CryptoConvertProcessing;
                          bool isEstimating = convertState is CryptoConvertEstimatingRate;
                          // Use the 'canAttemptConvert' derived earlier for clarity
                          return ElevatedButton(
                            onPressed: (isProcessing || isEstimating || !canAttemptConvert) ? null : _handleConvertPressed,
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: (isProcessing || isEstimating || !canAttemptConvert) ? Colors.grey : Theme.of(context).primaryColor,
                            ),
                            child: Center(
                              child: (isProcessing)
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                                : const Text("Convert", style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
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
      String? dropdownValue = value;
      // Ensure the value is either null or present in the items. If not, make it null or first item.
      if (items.isEmpty) {
        dropdownValue = null; // No items, so value must be null
      } else if (dropdownValue != null && !items.contains(dropdownValue)) {
        dropdownValue = items.first; // Or null, if you prefer a hint to show
      } else if (dropdownValue == null && items.isNotEmpty) {
        // If value is null but there are items, you might want to default to the first one
        // or let the hint text show. For controlled component, usually better to set explicitly or keep null.
        // For now, let it be null if it was null to show hint initially.
      }

     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: dropdownValue,
            hint: const Text("Select Coin", style: TextStyle(fontSize: 14, color: Colors.grey)),
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            items: items.map((itemValue) => DropdownMenuItem(value: itemValue, child: Text(itemValue, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
            itemHeight: kMinInteractiveDimension,
          ),
        ),
      );
  }

  // Modify _dropdownField to accept the filtered list of items (display names)
  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items, // Changed from List<CoinDisplayInfo> to List<String>
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        _buildDropdown( // _buildDropdown already takes List<String> items
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}