import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/digital_note_model.dart';
import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/logic/bloc/admin_digital_note/admin_digital_note_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AdminDigitalNotesView extends StatelessWidget {
  const AdminDigitalNotesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminDigitalNoteBloc(
        adminRepository: RepositoryProvider.of(context),
      ),
      child: BlocConsumer<AdminDigitalNoteBloc, AdminDigitalNoteState>(
        listener: (context, state) {
          if (state is DepositSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
           if (state is AdminDigitalNoteError && state.message.contains("not found")) {
            // Do nothing here for "not found", as it's handled in the builder
          } else if (state is AdminDigitalNoteError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: UserSearchBox(),
              ),
              if (state is AdminDigitalNoteLoading)
                const Expanded(child: Center(child: CircularProgressIndicator())),
              if (state is AdminDigitalNoteError)
                Expanded(child: Center(child: Text(state.message))),
              if (state is UserNotesLoaded)
                Expanded(
                  child: UserNotesProfile(
                    user: state.user,
                    notes: state.notes,
                    totalBalance: state.totalBalance,
                    isDepositing: state is DepositInProgress,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class UserSearchBox extends StatefulWidget {
  const UserSearchBox({super.key});
  @override
  State<UserSearchBox> createState() => _UserSearchBoxState();
}

class _UserSearchBoxState extends State<UserSearchBox> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Search User by Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.read<AdminDigitalNoteBloc>().add(SearchUserByEmail(value));
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              context.read<AdminDigitalNoteBloc>().add(SearchUserByEmail(_controller.text));
              FocusScope.of(context).unfocus();
            }
          },
        ),
         IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _controller.clear();
            context.read<AdminDigitalNoteBloc>().add(ClearSearch());
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }
}

class UserNotesProfile extends StatelessWidget {
  final UserModel user;
  final List<DigitalNoteModel> notes;
  final double totalBalance;
  final bool isDepositing;

  const UserNotesProfile({
    super.key,
    required this.user,
    required this.notes,
    required this.totalBalance,
    this.isDepositing = false,
  });

  void _showDepositDialog(BuildContext context) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final userEmail = user.userEmail;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Deposit to ${user.userName}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount to Deposit',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty || (double.tryParse(value) ?? 0) <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                   final userQuery = await FirebaseFirestore.instance.collection('users').where('user_email', isEqualTo: userEmail).get();
                   final userId = userQuery.docs.first.id;
                   
                  BlocProvider.of<AdminDigitalNoteBloc>(context).add(
                    DepositNotesToUser(userId: userId, amount: amount),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Confirm Deposit'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat.currency(locale: 'en_BD', symbol: '৳').format(totalBalance);
    
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(user.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user.userEmail),
          trailing: isDepositing 
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Deposit'),
                onPressed: () => _showDepositDialog(context),
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Total Note Balance: $formattedBalance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(),
        Expanded(
          child: notes.isEmpty
            ? const Center(child: Text('This user has no active digital notes.'))
            : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(NumberFormat.currency(locale: 'en_BD', symbol: '৳').format(note.denomination)),
                  subtitle: Text(note.serialNumber, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  trailing: Text(note.status, style: TextStyle(color: note.status == 'active' ? Colors.green : Colors.red)),
                );
              },
            ),
        ),
      ],
    );
  }
}