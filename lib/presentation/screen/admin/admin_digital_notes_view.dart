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
      create: (context) =>
          AdminDigitalNoteBloc(adminRepository: RepositoryProvider.of(context)),
      child: BlocConsumer<AdminDigitalNoteBloc, AdminDigitalNoteState>(
        listener: (context, state) {
          final bloc = context.read<AdminDigitalNoteBloc>();

          if (state is ActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade600,
              ),
            );
            // After an action, decide how to refresh the data based on the PREVIOUS state
            // This is a more complex pattern for when the ActionInProgress state doesn't hold old data.
            // For now, we will handle refresh inside the bloc. A better way might be to get the previous
            // state from the listener if the bloc library supports it easily, or hold it in the UI state.
            // A simplified approach is just to refresh based on the current context.
            // The BLoC now handles refreshing after a successful action.
          } else if (state is AdminDigitalNoteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
        builder: (context, state) {
          // --- THIS IS THE KEY UI FIX ---
          // Determine what view to show based on the state.
          // If the state is ActionInProgress, we show its previousState.
          Widget currentView;
          bool isProcessing = state is ActionInProgress;

          AdminDigitalNoteState stateToShow = isProcessing
              ? (state).previousState
              : state;

          if (stateToShow is AdminDigitalNoteLoading) {
            currentView = const Expanded(
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (stateToShow is AdminDigitalNoteError) {
            currentView = Expanded(
              child: Center(child: Text(stateToShow.message)),
            );
          } else if (stateToShow is UserNotesLoaded) {
            currentView = Expanded(
              child: UserNotesProfile(
                key: ValueKey(stateToShow.userId),
                userId: stateToShow.userId,
                user: stateToShow.user,
                notes: stateToShow.notes,
                totalBalance: stateToShow.totalBalance,
                isProcessingAction: isProcessing,
              ),
            );
          } else if (stateToShow is TransactionNotesLoaded) {
            currentView = Expanded(
              child: AdminTransactionNotesView(
                transactionId: stateToShow.transactionId,
                notes: stateToShow.notes,
                isProcessing: isProcessing,
              ),
            );
          } else {
            // AdminDigitalNoteInitial
            currentView = const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Search for a user or transaction to begin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              UserSearchBox(),
              const Divider(indent: 16, endIndent: 16, height: 1),
              TransactionSearchBox(),
              const Divider(),
              currentView,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search User by Email',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<AdminDigitalNoteBloc>().add(
                    SearchUserByEmail(value),
                  );
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search User",
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                context.read<AdminDigitalNoteBloc>().add(
                  SearchUserByEmail(_controller.text),
                );
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ],
      ),
    );
  }
}

class TransactionSearchBox extends StatefulWidget {
  const TransactionSearchBox({super.key});

  @override
  State<TransactionSearchBox> createState() => _TransactionSearchBoxState();
}

class _TransactionSearchBoxState extends State<TransactionSearchBox> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search by Transaction ID',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => _search(context, value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search Transaction",
            onPressed: () => _search(context, _controller.text),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: "Clear Search",
            onPressed: () {
              _controller.clear();
              context.read<AdminDigitalNoteBloc>().add(ClearNoteSearch());
              FocusScope.of(context).unfocus();
            },
          ),
        ],
      ),
    );
  }

  void _search(BuildContext context, String value) {
    if (value.trim().isNotEmpty) {
      context.read<AdminDigitalNoteBloc>().add(SearchTransactionById(value));
    } else {
      context.read<AdminDigitalNoteBloc>().add(ClearNoteSearch());
    }
    FocusScope.of(context).unfocus();
  }
}

class UserNotesProfile extends StatelessWidget {
  final String userId;
  final UserModel user;
  final List<DigitalNoteModel> notes;
  final double totalBalance;
  final bool isProcessingAction;

  const UserNotesProfile({
    super.key,
    required this.userId,
    required this.user,
    required this.notes,
    required this.totalBalance,
    this.isProcessingAction = false,
  });

  void _showDepositDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !isProcessingAction,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<AdminDigitalNoteBloc>(context),
          child: _DepositDialog(userId: userId, userName: user.userName),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat.currency(
      locale: 'en_BD',
      symbol: '৳',
    ).format(totalBalance);

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoUrl.isNotEmpty
                ? NetworkImage(user.photoUrl)
                : null,
            child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(
            user.userName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(user.userEmail),
          trailing: isProcessingAction
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
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
              ? const Center(
                  child: Text('This user has no active digital notes.'),
                )
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return AdminNoteCard(note: note);
                  },
                ),
        ),
      ],
    );
  }
}

class AdminNoteCard extends StatelessWidget {
  final DigitalNoteModel note;
  const AdminNoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final formattedDenomination = NumberFormat.currency(
      locale: 'en_BD',
      symbol: '৳',
    ).format(note.denomination);
    final bool isActive = note.status == 'active';
    final Color statusColor = isActive ? Colors.green : Colors.red;
    final Color cardColor = isActive
        ? Theme.of(context).cardColor
        : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: cardColor,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: ListTile(
          title: Text(
            formattedDenomination,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                'S/N: ${note.serialNumber}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
              Text(
                'From: ${note.receivedFromEmail}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'block') {
                    context.read<AdminDigitalNoteBloc>().add(
                      UpdateNoteStatusRequested(
                        noteId: note.noteId,
                        newStatus: 'blocked',
                      ),
                    );
                  } else if (value == 'activate') {
                    context.read<AdminDigitalNoteBloc>().add(
                      UpdateNoteStatusRequested(
                        noteId: note.noteId,
                        newStatus: 'active',
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (isActive)
                    const PopupMenuItem<String>(
                      value: 'block',
                      child: Text('Block Note'),
                    ),
                  if (!isActive)
                    const PopupMenuItem<String>(
                      value: 'activate',
                      child: Text('Activate Note'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'history',
                    child: Text('View History'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepositDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const _DepositDialog({required this.userId, required this.userName});

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onConfirmDeposit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      context.read<AdminDigitalNoteBloc>().add(
        DepositNotesToUser(userId: widget.userId, amount: amount),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminDigitalNoteBloc, AdminDigitalNoteState>(
      listener: (context, state) {
        if (state is ActionSuccess) {
          Navigator.of(context).pop();
        }
      },
      child: AlertDialog(
        title: Text('Deposit to ${widget.userName}'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _amountController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount to Deposit',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  (int.tryParse(value) ?? 0) <= 0) {
                return 'Please enter a valid positive amount';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<AdminDigitalNoteBloc, AdminDigitalNoteState>(
            builder: (context, state) {
              if (state is ActionInProgress) {
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
                onPressed: _onConfirmDeposit,
                child: const Text('Confirm Deposit'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminTransactionNotesView extends StatelessWidget {
  final String transactionId;
  final List<DigitalNoteModel> notes;
  final bool isProcessing;

  const AdminTransactionNotesView({
    super.key,
    required this.transactionId,
    required this.notes,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "Notes associated with Transaction:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectableText(
                transactionId,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              if (isProcessing)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Confirm Action'),
                        content: const Text(
                          'Are you sure you want to block all notes from this transaction?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<AdminDigitalNoteBloc>().add(
                                BlockNotesByTransactionId(transactionId),
                              );
                              Navigator.of(dialogContext).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Block Notes'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.block),
                  label: const Text("Block All Notes from this Txn"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return AdminNoteCard(note: notes[index]);
            },
          ),
        ),
      ],
    );
  }
}
