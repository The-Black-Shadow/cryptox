import 'package:cryptox/logic/bloc/digital_note/digital_note_bloc.dart';
import 'package:cryptox/logic/bloc/send_digital_note/send_digital_note_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SendDigitalNoteScreen extends StatefulWidget {
  const SendDigitalNoteScreen({super.key});

  @override
  State<SendDigitalNoteScreen> createState() => _SendDigitalNoteScreenState();
}

class _SendDigitalNoteScreenState extends State<SendDigitalNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSendPressed(double currentBalance) {
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
    // This screen needs its own BLoC for handling the 'send' action.
    return BlocProvider(
      create: (context) => SendDigitalNoteBloc(
        digitalNoteRepository: RepositoryProvider.of(context),
      ),
      child: BlocListener<SendDigitalNoteBloc, SendDigitalNoteState>(
        listener: (context, state) {
          if (state is SendDigitalNoteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh the user's wallet on the previous screen
            context.read<DigitalNoteBloc>().add(LoadDigitalNotes());
            Navigator.of(context).pop();
          } else if (state is SendDigitalNoteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Send Digital Notes')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            // This BlocBuilder now correctly listens to the DigitalNoteBloc instance
            // that was passed from the parent WalletScreen via context.
            child: BlocBuilder<DigitalNoteBloc, DigitalNoteState>(
              builder: (context, walletState) {
                final currentBalance = (walletState is DigitalNoteLoaded)
                    ? walletState.totalBalance
                    : 0.0;

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your Balance: ৳${currentBalance.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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
                          if (amount > currentBalance) {
                            return 'Insufficient balance';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      BlocBuilder<SendDigitalNoteBloc, SendDigitalNoteState>(
                        builder: (context, sendState) {
                          if (sendState is SendDigitalNoteInProgress) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return ElevatedButton(
                            onPressed: () => _onSendPressed(currentBalance),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Confirm & Send',
                              style: TextStyle(fontSize: 18),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
