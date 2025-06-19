import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/logic/bloc/digital_note/digital_note_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DigitalNoteScreen extends StatelessWidget {
  const DigitalNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the BLoC locally to this screen.
    // It will be created when the screen is opened and destroyed when it's closed.
    return BlocProvider(
      create: (context) =>
          DigitalNoteBloc(digitalNoteRepository: RepositoryProvider.of(context))
            ..add(LoadDigitalNotes()),
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
                if (state.notes.isEmpty) {
                  return const Center(
                    child: Text(
                      'You have no digital notes.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }
                return Column(
                  children: [
                    // Total Balance Header
                    TotalBalanceHeader(balance: state.totalBalance),
                    // List of Notes
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
              // Initial state
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
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
      margin: const EdgeInsets.all(16.0),
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
    final receivedFrom =
        note.receivedFromEmail; // Using the helper from the model

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
