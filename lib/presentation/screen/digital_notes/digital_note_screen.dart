import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/repositories/digital_note_repository.dart';
import 'package:cryptox/logic/bloc/digital_note/digital_note_bloc.dart';
import 'package:cryptox/logic/bloc/send_digital_note/send_digital_note_bloc.dart';
import 'package:flutter/material.dart';
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
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Send Digital Notes'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Trigger the dialog with the current balance
                          _showSendDialog(context, state.totalBalance);
                        },
                      ),
                    ),
                    const Divider(height: 24),
                    if (state.notes.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'You have no digital notes.',
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
    // --- THIS IS THE FIX ---
    // 1. Get the repository from the screen's context, which can see it.
    final digitalNoteRepository = RepositoryProvider.of<DigitalNoteRepository>(
      context,
    );
    // 2. Get the main screen's BLoC instance to pass it down for refreshing later.
    final digitalNoteBloc = BlocProvider.of<DigitalNoteBloc>(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        // This is the dialog's local context
        // 3. Provide a NEW SendDigitalNoteBloc instance specifically for the dialog.
        //    Crucially, create it with the repository we fetched *before* showing the dialog.
        return BlocProvider(
          create: (dialogContext) =>
              SendDigitalNoteBloc(digitalNoteRepository: digitalNoteRepository),
          child: SendDigitalNoteDialog(
            currentBalance: currentBalance,
            digitalNoteBloc: digitalNoteBloc,
          ),
        );
      },
    );
  }
}

// --- WIDGETS ---

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
      final amountToSend = double.parse(_amountController.text);
      context.read<SendDigitalNoteBloc>().add(
        SendNotesSubmitted(
          recipientEmail: _recipientController.text.trim(),
          amount: amountToSend,
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
          // Use the BLoC instance passed from the parent screen to refresh its data
          widget.digitalNoteBloc.add(LoadDigitalNotes());
          Navigator.of(context).pop(); // Close the dialog
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  if (amount > widget.currentBalance) {
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
