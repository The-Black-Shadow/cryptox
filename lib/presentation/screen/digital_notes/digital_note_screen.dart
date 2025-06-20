import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/models/digital_note_transaction_model.dart';
import 'package:cryptox/data/repositories/digital_note_repository.dart';
import 'package:cryptox/logic/bloc/digital_note/digital_note_bloc.dart';
import 'package:cryptox/logic/bloc/digital_note_history/digital_note_history_bloc.dart';
import 'package:cryptox/logic/bloc/send_digital_note/send_digital_note_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DigitalNoteScreen extends StatelessWidget {
  const DigitalNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DigitalNoteBloc(
        digitalNoteRepository: RepositoryProvider.of<DigitalNoteRepository>(
          context,
        ),
      )..add(LoadDigitalNotes()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Digital Notes Wallet'),
          backgroundColor: Colors.teal,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<DigitalNoteBloc>().add(LoadDigitalNotes());
          },
          child: BlocBuilder<DigitalNoteBloc, DigitalNoteState>(
            builder: (context, state) {
              if (state is DigitalNoteLoading && state is! DigitalNoteLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DigitalNoteError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(state.message, textAlign: TextAlign.center),
                  ),
                );
              }
              if (state is DigitalNoteLoaded) {
                return Column(
                  children: [
                    TotalBalanceHeader(balance: state.totalBalance),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Send Notes'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  _showSendDialog(context, state.totalBalance),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.history),
                              label: const Text('History'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                backgroundColor: Colors.cyan,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showHistoryDialog(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    if (state.notes.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'You have no active digital notes.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.notes.length,
                          itemBuilder: (context, index) {
                            final note = state.notes[index];
                            return NoteCard(note: note);
                          },
                        ),
                      ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  void _showSendDialog(BuildContext context, double currentBalance) {
    final digitalNoteBloc = BlocProvider.of<DigitalNoteBloc>(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return BlocProvider(
          create: (dialogContext) => SendDigitalNoteBloc(
            digitalNoteRepository: RepositoryProvider.of<DigitalNoteRepository>(
              context,
            ),
          ),
          child: SendDigitalNoteDialog(
            currentBalance: currentBalance,
            digitalNoteBloc: digitalNoteBloc,
          ),
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider(
          create: (dialogContext) => DigitalNoteHistoryBloc(
            digitalNoteRepository: RepositoryProvider.of<DigitalNoteRepository>(
              context,
            ),
          )..add(LoadNoteHistory()),
          child: const HistoryDialog(),
        );
      },
    );
  }
}

class TotalBalanceHeader extends StatelessWidget {
  final double balance;
  const TotalBalanceHeader({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat.currency(
      locale: 'en_BD',
      symbol: '৳',
    ).format(balance);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Digital Note Balance',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedBalance,
            style: const TextStyle(
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final DigitalNoteModel note;
  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final formattedDenomination = NumberFormat.currency(
      locale: 'en_BD',
      symbol: '৳',
    ).format(note.denomination);
    final receivedFrom = note.receivedFromEmail;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: Text(
            '৳',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          formattedDenomination,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Received from: $receivedFrom',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          note.serialNumber,
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class SendDigitalNoteDialog extends StatefulWidget {
  final double currentBalance;
  final DigitalNoteBloc digitalNoteBloc;
  const SendDigitalNoteDialog({
    super.key,
    required this.currentBalance,
    required this.digitalNoteBloc,
  });

  @override
  State<SendDigitalNoteDialog> createState() => _SendDigitalNoteDialogState();
}

class _SendDigitalNoteDialogState extends State<SendDigitalNoteDialog> {
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
      context.read<SendDigitalNoteBloc>().add(
        SendNotesSubmitted(
          recipientEmail: _recipientController.text.trim(),
          amount: double.parse(_amountController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendDigitalNoteBloc, SendDigitalNoteState>(
      listener: (context, state) {
        if (state is SendDigitalNoteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          widget.digitalNoteBloc.add(LoadDigitalNotes());
          Navigator.of(context).pop();
        } else if (state is SendDigitalNoteFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Send Digital Notes'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Balance: ৳${widget.currentBalance.toStringAsFixed(2)}',
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
                  labelText: 'Amount (Taka)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter an amount';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0)
                    return 'Please enter a valid positive amount';
                  if (amount > widget.currentBalance)
                    return 'Insufficient balance';
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
          BlocBuilder<SendDigitalNoteBloc, SendDigitalNoteState>(
            builder: (context, state) {
              if (state is SendDigitalNoteInProgress) {
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

class HistoryDialog extends StatelessWidget {
  const HistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transaction History'),
      content: SizedBox(
        width: double.maxFinite,
        child: BlocBuilder<DigitalNoteHistoryBloc, DigitalNoteHistoryState>(
          builder: (context, state) {
            if (state is DigitalNoteHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DigitalNoteHistoryError) {
              return Center(
                child: Text(state.message, textAlign: TextAlign.center),
              );
            }
            if (state is DigitalNoteHistoryLoaded) {
              if (state.transactions.isEmpty) {
                return const Center(
                  child: Text("No transaction history found."),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: state.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = state.transactions[index];
                  return HistoryCard(transaction: transaction);
                },
              );
            }
            return const Center(child: Text("Loading..."));
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class HistoryCard extends StatelessWidget {
  final DigitalNoteTransactionModel transaction;
  const HistoryCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final bool isSent = transaction.senderId == currentUser.uid;
    final iconColor = isSent ? Colors.red : Colors.green;
    final title = isSent
        ? 'Sent to: ${transaction.recipientEmail}'
        : 'Received from: ${transaction.senderEmail}';
    final amountString =
        '${isSent ? '-' : '+'}৳${transaction.totalSentAmount.toStringAsFixed(2)}';
    final formattedDate = DateFormat(
      'MMM dd, yyyy – hh:mm a',
    ).format(transaction.timestamp.toDate());

    return ListTile(
      leading: Icon(
        isSent
            ? Icons.arrow_circle_up_outlined
            : Icons.arrow_circle_down_outlined,
        color: iconColor,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formattedDate, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 2),
          SelectableText(
            'Txn ID: ${transaction.transactionId}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      trailing: Text(
        amountString,
        style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
