import 'package:cryptox/data/models/transaction_record_model.dart';
import 'package:cryptox/logic/bloc/transaction_history/transaction_history_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionHistoryBloc(
        walletRepository: RepositoryProvider.of(context),
      )..add(LoadUserTransactions()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Transaction History')),
        body: BlocBuilder<TransactionHistoryBloc, TransactionHistoryState>(
          builder: (context, state) {
            if (state is TransactionHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TransactionHistoryLoaded) {
              if (state.transactions.isEmpty) {
                return const Center(
                  child: Text(
                    'You have no transactions yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TransactionHistoryBloc>().add(
                    LoadUserTransactions(),
                  );
                },
                child: ListView.builder(
                  itemCount: state.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = state.transactions[index];
                    return UserTransactionCard(transaction: transaction);
                  },
                ),
              );
            }
            if (state is TransactionHistoryError) {
              return Center(child: Text("Error: ${state.message}"));
            }
            return const Center(child: Text("Loading history..."));
          },
        ),
      ),
    );
  }
}

class UserTransactionCard extends StatelessWidget {
  final TransactionRecordModel transaction;
  const UserTransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final bool isSentTransaction = transaction.fromUserId == currentUser.uid;
    final formattedDate = DateFormat(
      'MMM dd, yyyy – hh:mm a',
    ).format(transaction.timestamp.toDate());

    final IconData iconData = isSentTransaction
        ? Icons.arrow_upward
        : Icons.arrow_downward;
    final Color iconColor = isSentTransaction ? Colors.red : Colors.green;
    final String title = isSentTransaction
        ? 'Sent to: ${transaction.toUserEmail}'
        : 'Received from: ${transaction.fromUserEmail}';

    // --- THIS IS THE MODIFIED LOGIC ---
    final String amountString;
    // Check if the coin type is Tether (case-insensitive check)
    if (transaction.coinType.toLowerCase() == 'tether') {
      amountString =
          '${isSentTransaction ? '-' : '+'} ${transaction.totalAmount.toStringAsFixed(2)} ${transaction.coinType.toUpperCase()}';
    } else {
      // For all other coins, use 10 decimal places
      amountString =
          '${isSentTransaction ? '-' : '+'} ${transaction.totalAmount.toStringAsFixed(10)} ${transaction.coinType.toUpperCase()}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2), // Small spacing
            Text(
              formattedDate,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            // Use SelectableText so the user can easily copy the ID.
            SelectableText(
              'ID: ${transaction.transactionId}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontFamily:
                    'monospace', // Monospace font makes IDs easier to read
              ),
            ),
          ],
        ),
        trailing: Text(
          amountString,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // Optional: You could show an AlertDialog with even more details here if needed.
        },
      ),
    );
  }
}
