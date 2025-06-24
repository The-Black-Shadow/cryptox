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
            currentView = Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(),
                ),
              ),
            );
          } else if (stateToShow is AdminDigitalNoteError) {
            currentView = Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        stateToShow.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
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
            currentView = Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.search,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Search for Digital Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter a user email or transaction ID to begin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Search Cards
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const UserSearchBox(),
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const TransactionSearchBox(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                currentView,
              ],
            ),
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
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Search User by Email',
        hintText: 'Enter user email address...',
        prefixIcon: const Icon(Icons.person_search, color: Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                context.read<AdminDigitalNoteBloc>().add(
                  SearchUserByEmail(_controller.text),
                );
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          context.read<AdminDigitalNoteBloc>().add(SearchUserByEmail(value));
        }
      },
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Search by Transaction ID',
              hintText: 'Enter transaction ID...',
              prefixIcon: const Icon(
                Icons.receipt_long,
                color: Color(0xFF667eea),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF667eea),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (value) => _search(context, value),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _search(context, _controller.text),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _controller.clear();
              context.read<AdminDigitalNoteBloc>().add(ClearNoteSearch());
              FocusScope.of(context).unfocus();
            },
          ),
        ),
      ],
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? NetworkImage(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.userEmail,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isProcessingAction)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Deposit'),
                    onPressed: () => _showDepositDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667eea),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Balance Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Note Balance',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      formattedBalance,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.grey.shade200,
          ),
          // Notes List
          Expanded(
            child: notes.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Digital Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This user has no active digital notes.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return AdminNoteCard(note: note);
                    },
                  ),
          ),
        ],
      ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.block,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDenomination,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    'S/N: ${note.serialNumber}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: ${note.receivedFromEmail}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (isActive)
                    const PopupMenuItem<String>(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Block Note'),
                        ],
                      ),
                    ),
                  if (!isActive)
                    const PopupMenuItem<String>(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text('Activate Note'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Deposit to ${widget.userName}')),
          ],
        ),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _amountController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Amount to Deposit',
              hintText: 'Enter amount in BDT...',
              prefixIcon: const Icon(
                Icons.attach_money,
                color: Color(0xFF667eea),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF667eea),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
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
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          BlocBuilder<AdminDigitalNoteBloc, AdminDigitalNoteState>(
            builder: (context, state) {
              if (state is ActionInProgress) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ElevatedButton(
                    onPressed: null,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      shadowColor: WidgetStatePropertyAll(Colors.transparent),
                    ),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _onConfirmDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Deposit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Transaction Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Transaction Notes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    transactionId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions Section
          Container(
            padding: const EdgeInsets.all(20),
            child: isProcessing
                ? const CircularProgressIndicator()
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(Icons.block, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Block Notes'),
                                  ],
                                ),
                                content: const Text(
                                  'Are you sure you want to block all notes from this transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<AdminDigitalNoteBloc>().add(
                                        BlockNotesByTransactionId(
                                          transactionId,
                                        ),
                                      );
                                      Navigator.of(dialogContext).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Block Notes'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.block),
                          label: const Text("Block All"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Enable Notes'),
                                  ],
                                ),
                                content: const Text(
                                  'Are you sure you want to enable all notes from this transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<AdminDigitalNoteBloc>().add(
                                        EnableNotesByTransactionId(
                                          transactionId,
                                        ),
                                      );
                                      Navigator.of(dialogContext).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Enable Notes'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Enable All"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.grey.shade200,
          ),
          // Notes List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return AdminNoteCard(note: notes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
