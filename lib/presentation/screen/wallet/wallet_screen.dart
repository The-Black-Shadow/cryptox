import 'package:cryptox/data/models/coin_display_info.dart';
import 'package:cryptox/data/models/crypto_balance_model.dart';
import 'package:cryptox/logic/bloc/crypto_convert/crypto_convert_bloc.dart';
import 'package:cryptox/logic/bloc/send_crypto/send_crypto_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/presentation/widgets/custom_dropdown_field.dart';
import 'package:cryptox/presentation/widgets/wallet_buton.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:go_router/go_router.dart';

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
    context.read<WalletBalanceBloc>().add(LoadWalletBalance());

    _amountDebouncer = Debouncer(
      const Duration(milliseconds: 700),
      initialValue: '',
    );
    _amountDebouncer.values.listen((amountString) {
      if (mounted) _triggerRateEstimation();
    });

    amountController.addListener(() {
      if (mounted) _amountDebouncer.value = amountController.text;
    });
  }

  void _triggerRateEstimation() {
    if (!mounted) return;

    bool canCurrentlyConvert =
        _fromCoinDisplayName != null &&
        _toCoinDisplayName != null &&
        _fromCoinDisplayName != _toCoinDisplayName &&
        amountController.text.isNotEmpty &&
        (double.tryParse(amountController.text) ?? 0.0) > 0;

    if (canCurrentlyConvert) {
      final fromCoinInfo = supportedCoinsDisplayInfo.firstWhere(
        (c) => c.displayName == _fromCoinDisplayName,
      );
      final toCoinInfo = supportedCoinsDisplayInfo.firstWhere(
        (c) => c.displayName == _toCoinDisplayName,
      );
      context.read<CryptoConvertBloc>().add(
        ConversionInputsChanged(
          fromCoinGeckoId: fromCoinInfo.coinGeckoId,
          toCoinGeckoId: toCoinInfo.coinGeckoId,
          amountString: amountController.text,
        ),
      );
    } else {
      setState(() {
        estimatedController.text = '';
        _currentRateInfo = null;
      });
      if (context.read<CryptoConvertBloc>().state is! CryptoConvertInitial &&
          context.read<CryptoConvertBloc>().state
              is! CryptoConvertEstimatingRate) {
        context.read<CryptoConvertBloc>().add(
          const ConversionInputsChanged(
            fromCoinGeckoId: null,
            toCoinGeckoId: null,
            amountString: '0',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    amountController.removeListener(() {
      if (mounted) _amountDebouncer.value = amountController.text;
    });
    amountController.dispose();
    estimatedController.dispose();
    super.dispose();
  }

  double _getBalanceForFirestoreKey(
    CryptoBalance balances,
    String firestoreKey,
  ) {
    switch (firestoreKey) {
      case 'bitcoin':
        return balances.bitcoin;
      case 'ethereum':
        return balances.ethereum;
      case 'bnb':
        return balances.bnb;
      case 'x':
        return balances.x;
      case 'tether':
        return balances.tether;
      default:
        return 0.0;
    }
  }

  void _handleConvertPressed() {
    if (!mounted) return;

    final walletState = context.read<WalletBalanceBloc>().state;
    if (walletState is! WalletBalanceLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wallet balances not loaded.")),
      );
      return;
    }

    if (_fromCoinDisplayName == null || _toCoinDisplayName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select coins to convert.")),
      );
      return;
    }

    final fromCoinInfo = supportedCoinsDisplayInfo.firstWhere(
      (c) => c.displayName == _fromCoinDisplayName,
    );
    final toCoinInfo = supportedCoinsDisplayInfo.firstWhere(
      (c) => c.displayName == _toCoinDisplayName,
    );

    if (fromCoinInfo.firestoreKey != 'tether' &&
        toCoinInfo.firestoreKey != 'tether') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Conversions must involve USDT.")),
      );
      return;
    }

    final double amountFrom = double.tryParse(amountController.text) ?? 0.0;
    if (amountFrom <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount.")),
      );
      return;
    }

    final double currentFromBalance = _getBalanceForFirestoreKey(
      walletState.cryptoBalance,
      fromCoinInfo.firestoreKey,
    );
    if (currentFromBalance < amountFrom) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient ${fromCoinInfo.displayName} balance."),
        ),
      );
      return;
    }

    context.read<CryptoConvertBloc>().add(
      ExecuteConversionRequested(
        fromCoinInfo: fromCoinInfo,
        toCoinInfo: toCoinInfo,
        amountFrom: amountFrom,
      ),
    );
  }

  void _initializeDropdownSelections(List<CoinDisplayInfo> availableCoins) {
    if (!mounted) return;
    setState(() {
      if (selectedCoinName == null && availableCoins.isNotEmpty) {
        selectedCoinName = availableCoins.first.displayName;
      }
      if (_fromCoinDisplayName == null && availableCoins.isNotEmpty) {
        _fromCoinDisplayName = availableCoins.first.displayName;
      }
      if ((_toCoinDisplayName == null ||
              (_fromCoinDisplayName == _toCoinDisplayName)) &&
          availableCoins.isNotEmpty) {
        _toCoinDisplayName = availableCoins
            .firstWhere(
              (coin) => coin.displayName != _fromCoinDisplayName,
              orElse: () => availableCoins.first,
            )
            .displayName;
      }
    });
  }

  void _showSendDialog(BuildContext context, double currentTetherBalance) {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: BlocProvider.of<SendCryptoBloc>(context),
          child: SendCryptoDialog(currentTetherBalance: currentTetherBalance),
        );
      },
    );
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'My Wallet',
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
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<WalletBalanceBloc, WalletBalanceState>(
                      listener: (context, state) {
                        if (state is WalletBalanceLoaded) {
                          _initializeDropdownSelections(state.availableCoins);
                        }
                      },
                    ),
                    BlocListener<CryptoConvertBloc, CryptoConvertState>(
                      listener: (context, state) {
                        if (!mounted) return;
                        if (state is CryptoConvertRateLoaded) {
                          final currentAmount =
                              double.tryParse(amountController.text) ?? -1;
                          final fromInfo = _fromCoinDisplayName != null
                              ? supportedCoinsDisplayInfo.firstWhere(
                                  (c) => c.displayName == _fromCoinDisplayName,
                                )
                              : null;
                          final toInfo = _toCoinDisplayName != null
                              ? supportedCoinsDisplayInfo.firstWhere(
                                  (c) => c.displayName == _toCoinDisplayName,
                                )
                              : null;

                          if (fromInfo != null &&
                              toInfo != null &&
                              state.amountFrom == currentAmount &&
                              state.fromCoinGeckoId == fromInfo.coinGeckoId &&
                              state.toCoinGeckoId == toInfo.coinGeckoId) {
                            setState(() {
                              estimatedController.text =
                                  "${state.estimatedAmountTo.toStringAsFixed(8)} ${toInfo.symbol}";
                              _currentRateInfo = state;
                            });
                          }
                        } else if (state is CryptoConvertEstimatingRate) {
                          setState(() {
                            estimatedController.text = 'Estimating...';
                            _currentRateInfo = null;
                          });
                        } else if (state is CryptoConvertRateError) {
                          setState(() {
                            estimatedController.text = 'Error fetching rate';
                            _currentRateInfo = null;
                          });
                        } else if (state is CryptoConvertSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.green,
                            ),
                          );
                          amountController.clear();
                        } else if (state is CryptoConvertFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Conversion Failed: ${state.message}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  child: BlocBuilder<WalletBalanceBloc, WalletBalanceState>(
                    builder: (context, walletState) {
                      if (walletState is WalletBalanceLoading ||
                          walletState is WalletBalanceInitial) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      } else if (walletState is WalletBalanceLoaded) {
                        final currentSelectedCoinInfo = selectedCoinName != null
                            ? walletState.availableCoins.firstWhere(
                                (c) => c.displayName == selectedCoinName,
                                orElse: () => walletState.availableCoins.first,
                              )
                            : walletState.availableCoins.first;
                        final selectedBalanceAmount =
                            _getBalanceForFirestoreKey(
                              walletState.cryptoBalance,
                              currentSelectedCoinInfo.firestoreKey,
                            );
                        final selectedFormattedBalance =
                            '${selectedBalanceAmount.toStringAsFixed(6)} ${currentSelectedCoinInfo.symbol}';
                        final currentTetherBalance =
                            walletState.cryptoBalance.tether;

                        List<String> fromCoinItems = walletState.availableCoins
                            .where((c) => c.displayName != _toCoinDisplayName)
                            .map((info) => info.displayName)
                            .toList();
                        List<String> toCoinItems = walletState.availableCoins
                            .where((c) => c.displayName != _fromCoinDisplayName)
                            .map((info) => info.displayName)
                            .toList();

                        bool canAttemptConvert =
                            _fromCoinDisplayName != null &&
                            _toCoinDisplayName != null &&
                            _fromCoinDisplayName != _toCoinDisplayName &&
                            (double.tryParse(amountController.text) ?? 0.0) > 0;

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<WalletBalanceBloc>().add(
                              LoadWalletBalance(),
                            );
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Action Buttons Card
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Quick Actions',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF667eea),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: WalletButton(
                                              label: "Send USDT",
                                              icon: Icons.send,
                                              onPressed: () => _showSendDialog(
                                                context,
                                                currentTetherBalance,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: WalletButton(
                                              label: 'Deposit',
                                              icon:
                                                  Icons.file_download_outlined,
                                              onPressed: () =>
                                                  context.pushNamed(
                                                    Routes.PAYMENT_ROUTE,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: WalletButton(
                                              label: 'History',
                                              icon: Icons.history,
                                              onPressed: () => context.pushNamed(
                                                Routes
                                                    .TRANSACTION_HISTORY_ROUTE,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Crypto Balances Card
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "All Crypto Balances",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF667eea),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      CustomDropdownField(
                                        label: "",
                                        value: selectedCoinName,
                                        items: walletState.availableCoins
                                            .map((info) => info.displayName)
                                            .toList(),
                                        onChanged: (value) => setState(
                                          () => selectedCoinName = value,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF667eea,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF667eea,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              selectedCoinName ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF667eea),
                                              ),
                                            ),
                                            Text(
                                              selectedFormattedBalance,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Convert Coins Card
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Convert Coins",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF667eea),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomDropdownField(
                                              label: "From Coin",
                                              value: _fromCoinDisplayName,
                                              items: fromCoinItems,
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    _fromCoinDisplayName = val;
                                                    if (_fromCoinDisplayName ==
                                                            _toCoinDisplayName &&
                                                        _toCoinDisplayName !=
                                                            null) {
                                                      _toCoinDisplayName = walletState
                                                          .availableCoins
                                                          .firstWhere(
                                                            (coin) =>
                                                                coin.displayName !=
                                                                _fromCoinDisplayName,
                                                            orElse: () =>
                                                                walletState
                                                                    .availableCoins
                                                                    .first,
                                                          )
                                                          .displayName;
                                                    }
                                                  });
                                                  _triggerRateEstimation();
                                                }
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF667eea,
                                                ).withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.swap_horiz,
                                                size: 24,
                                                color: Color(0xFF667eea),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomDropdownField(
                                              label: "To Coin",
                                              value: _toCoinDisplayName,
                                              items: toCoinItems,
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    _toCoinDisplayName = val;
                                                    if (_toCoinDisplayName ==
                                                            _fromCoinDisplayName &&
                                                        _fromCoinDisplayName !=
                                                            null) {
                                                      _fromCoinDisplayName = walletState
                                                          .availableCoins
                                                          .firstWhere(
                                                            (coin) =>
                                                                coin.displayName !=
                                                                _toCoinDisplayName,
                                                            orElse: () =>
                                                                walletState
                                                                    .availableCoins
                                                                    .first,
                                                          )
                                                          .displayName;
                                                    }
                                                  });
                                                  _triggerRateEstimation();
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: amountController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: InputDecoration(
                                          labelText: "Amount to Convert",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF667eea),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      BlocBuilder<
                                        CryptoConvertBloc,
                                        CryptoConvertState
                                      >(
                                        builder: (context, convertState) {
                                          Widget suffix =
                                              const SizedBox.shrink();
                                          if (convertState
                                              is CryptoConvertEstimatingRate) {
                                            suffix = const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF667eea),
                                                    ),
                                              ),
                                            );
                                          }
                                          return TextField(
                                            controller: estimatedController,
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              labelText:
                                                  "You will receive (approx.)",
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF667eea),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              suffixIcon: suffix,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      BlocBuilder<
                                        CryptoConvertBloc,
                                        CryptoConvertState
                                      >(
                                        builder: (context, convertState) {
                                          bool isProcessing =
                                              convertState
                                                  is CryptoConvertProcessing;
                                          bool isEstimating =
                                              convertState
                                                  is CryptoConvertEstimatingRate;
                                          return SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed:
                                                  (isProcessing ||
                                                      isEstimating ||
                                                      !canAttemptConvert)
                                                  ? null
                                                  : _handleConvertPressed,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF667eea,
                                                ),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: (isProcessing)
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : const Text(
                                                      "Convert",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          );
                                        },
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
                      return Container(
                        alignment: Alignment.center,
                        child: Text(
                          walletState is WalletBalanceError
                              ? walletState.message
                              : 'An unknown error occurred.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ADD THIS WIDGET TO THE BOTTOM OF THE FILE ---
class SendCryptoDialog extends StatefulWidget {
  final double currentTetherBalance;
  const SendCryptoDialog({super.key, required this.currentTetherBalance});

  @override
  State<SendCryptoDialog> createState() => _SendCryptoDialogState();
}

class _SendCryptoDialogState extends State<SendCryptoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSendPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<SendCryptoBloc>().add(
        SendTetherSubmitted(
          recipientEmail: _recipientController.text.trim(),
          amount: double.parse(_amountController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendCryptoBloc, SendCryptoState>(
      listener: (context, state) {
        if (state is SendCryptoSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is SendCryptoFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Send USDT'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Balance: ${widget.currentTetherBalance.toStringAsFixed(4)} USDT',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (USDT)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  if (amount > widget.currentTetherBalance) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<SendCryptoBloc, SendCryptoState>(
            builder: (context, state) {
              if (state is SendCryptoInProgress) {
                return const ElevatedButton(
                  onPressed: null,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return ElevatedButton(
                onPressed: _onSendPressed,
                child: const Text('Send'),
              );
            },
          ),
        ],
      ),
    );
  }
}
