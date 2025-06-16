import 'package:cryptox/data/models/coin_display_info.dart';
import 'package:cryptox/data/models/crypto_balance_model.dart';
import 'package:cryptox/logic/bloc/send_crypto/send_crypto_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/presentation/widgets/custom_dropdown_field.dart';
import 'package:cryptox/presentation/widgets/wallet_buton.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String? selectedCoinName;

  @override
  void initState() {
    super.initState();
    // --- THIS IS THE KEY CHANGE ---
    // Always dispatch LoadWalletBalance when the screen becomes active.
    // The BLoC's `restartable()` transformer will handle this efficiently,
    // ensuring the listener is always active and fetches the latest data
    // without creating memory leaks.
    context.read<WalletBalanceBloc>().add(LoadWalletBalance());
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

  void _initializeDropdownSelections(List<CoinDisplayInfo> availableCoins) {
    if (!mounted) return;
    if (selectedCoinName == null && availableCoins.isNotEmpty) {
      setState(() {
        selectedCoinName = availableCoins.first.displayName;
      });
    }
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
      appBar: AppBar(title: const Text("My Wallet"), centerTitle: true),
      body: BlocListener<WalletBalanceBloc, WalletBalanceState>(
        listener: (context, state) {
          if (state is WalletBalanceLoaded) {
            _initializeDropdownSelections(state.availableCoins);
          } else if (state is WalletBalanceError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Wallet Error: ${state.message}')),
              );
            }
          }
        },
        child: BlocBuilder<WalletBalanceBloc, WalletBalanceState>(
          builder: (context, walletState) {
            if (walletState is WalletBalanceLoading ||
                walletState is WalletBalanceInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (walletState is WalletBalanceLoaded) {
              final CoinDisplayInfo? currentSelectedCoinInfo =
                  selectedCoinName != null
                  ? walletState.availableCoins.firstWhere(
                      (c) => c.displayName == selectedCoinName,
                      orElse: () => walletState.availableCoins.isNotEmpty
                          ? walletState.availableCoins.first
                          : supportedCoinsDisplayInfo.first,
                    )
                  : (walletState.availableCoins.isNotEmpty
                        ? walletState.availableCoins.first
                        : null);

              final double selectedBalanceAmount =
                  currentSelectedCoinInfo != null
                  ? _getBalanceForFirestoreKey(
                      walletState.cryptoBalance,
                      currentSelectedCoinInfo.firestoreKey,
                    )
                  : 0.0;

              final String selectedFormattedBalance =
                  currentSelectedCoinInfo != null
                  ? '${selectedBalanceAmount.toStringAsFixed(6)} ${currentSelectedCoinInfo.symbol}'
                  : '0.00';

              final double currentTetherBalance =
                  walletState.cryptoBalance.tether;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WalletBalanceBloc>().add(LoadWalletBalance());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          WalletButton(
                            label: "Send USDT",
                            icon: Icons.send,
                            onPressed: () {
                              _showSendDialog(context, currentTetherBalance);
                            },
                          ),
                          WalletButton(
                            label: 'Deposit',
                            icon: Icons.file_download_outlined,
                            onPressed: () =>
                                context.pushNamed(Routes.PAYMENT_ROUTE),
                          ),
                          WalletButton(
                            label: 'History',
                            icon: Icons.history,
                            onPressed: () => context.pushNamed(
                              Routes.TRANSACTION_HISTORY_ROUTE,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "All Crypto Balances",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomDropdownField(
                        label: "",
                        value: selectedCoinName,
                        items: walletState.availableCoins
                            .map((coinInfo) => coinInfo.displayName)
                            .toList(),
                        onChanged: (value) {
                          if (value != null && mounted) {
                            setState(() => selectedCoinName = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedCoinName ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
              );
            }
            return Center(
              child: Text(
                walletState is WalletBalanceError
                    ? walletState.message
                    : 'An unknown error occurred.',
              ),
            );
          },
        ),
      ),
    );
  }
}

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
