import 'package:cryptox/data/models/transaction_record_model.dart';
import 'package:cryptox/logic/bloc/admin_trace/admin_trace_bloc.dart';
import 'package:cryptox/logic/bloc/profile/profile_bloc.dart';
import 'package:cryptox/presentation/screen/admin/admin_digital_notes_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final List<String> _pageTitles = ['Transaction Trace', 'Digital Notes Admin'];

  static const List<Widget> _adminPages = <Widget>[
    AdminTraceView(),
    AdminDigitalNotesView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The global listener for logout is now in main.dart, so we don't need it here.
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // The global listener in main.dart will handle the navigation and state reset.
              context.read<ProfileBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _adminPages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu),
            label: 'Trace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            label: 'Digital Notes',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- VIEW FOR THE TRANSACTION TRACING TAB ---
class AdminTraceView extends StatelessWidget {
  const AdminTraceView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AdminTraceBloc(adminRepository: RepositoryProvider.of(context))
            ..add(LoadRecentTransactions()),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: TransactionSearchBox(),
          ),
          Expanded(
            child: BlocBuilder<AdminTraceBloc, AdminTraceState>(
              builder: (context, state) {
                if (state is AdminTraceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AdminTraceLoaded) {
                  if (state.transactions.isEmpty) {
                    return const Center(child: Text("No transactions found."));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<AdminTraceBloc>().add(
                        LoadRecentTransactions(),
                      );
                    },
                    child: ListView.builder(
                      itemCount: state.transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = state.transactions[index];
                        return TransactionCard(transaction: transaction);
                      },
                    ),
                  );
                }
                if (state is AdminTraceError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context.read<AdminTraceBloc>().add(
                            LoadRecentTransactions(),
                          ),
                          child: const Text("Show Recent Transactions"),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Text(
                    "Search for a transaction ID or pull to refresh.",
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- PLACEHOLDER VIEW FOR THE NEW DIGITAL NOTES TAB ---


// --- HELPER WIDGETS FOR THE TRACE VIEW ---

class TransactionSearchBox extends StatefulWidget {
  const TransactionSearchBox({super.key});
  @override
  State<TransactionSearchBox> createState() => _TransactionSearchBoxState();
}

class _TransactionSearchBoxState extends State<TransactionSearchBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Search by Transaction ID',
        hintText: 'Enter a full transaction ID...',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              context.read<AdminTraceBloc>().add(
                TraceTransactionRequested(_controller.text),
              );
            } else {
              context.read<AdminTraceBloc>().add(LoadRecentTransactions());
            }
            FocusScope.of(context).unfocus();
          },
        ),
      ),
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          context.read<AdminTraceBloc>().add(TraceTransactionRequested(value));
        } else {
          context.read<AdminTraceBloc>().add(LoadRecentTransactions());
        }
      },
    );
  }
}

class TransactionCard extends StatelessWidget {
  final TransactionRecordModel transaction;
  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final date = transaction.timestamp.toDate();
    final formattedDate = DateFormat('MMM dd, yyyy – hh:mm a').format(date);

    final String amountString;
    if (transaction.coinType.toLowerCase() == 'tether') {
      amountString =
          '${transaction.totalAmount.toStringAsFixed(2)} ${transaction.coinType.toUpperCase()}';
    } else {
      amountString =
          '${transaction.totalAmount.toStringAsFixed(10)} ${transaction.coinType.toUpperCase()}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          amountString,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formattedDate),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  "Txn ID: ${transaction.transactionId}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 20),
                _buildTraceRow('From:', transaction.fromUserEmail),
                const SizedBox(height: 8),
                _buildTraceRow('To:', transaction.toUserEmail),
                const SizedBox(height: 16),
                const Text(
                  "Inputs (Funds Consumed):",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...transaction.inputs.map((input) {
                  if (input.containsKey('parcelId')) {
                    final amount = (input['amount'] as num? ?? 0)
                        .toStringAsFixed(2);
                    return SelectableText(
                      "  - From ${transaction.fromUserEmail} [$amount USDT Parcel]",
                      style: const TextStyle(fontSize: 12),
                    );
                  } else {
                    final amount = (input['amount'] as num? ?? 0)
                        .toStringAsFixed(10);
                    final coin = (input['coin'] as String? ?? 'N/A')
                        .toUpperCase();
                    return SelectableText(
                      "  - From ${transaction.fromUserEmail} [$amount $coin Balance]",
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                }),
                const SizedBox(height: 16),
                const Text(
                  "Outputs (Funds Created):",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...transaction.outputs.map((output) {
                  if (output.containsKey('newParcelId')) {
                    final bool isChange =
                        output['recipientUserId'] == transaction.fromUserId;
                    final amount = (output['amount'] as num? ?? 0)
                        .toStringAsFixed(2);
                    final recipientEmail = isChange
                        ? transaction.fromUserEmail
                        : transaction.toUserEmail;
                    final newParcelId =
                        output['newParcelId'] as String? ?? 'N/A';

                    return InkWell(
                      onTap: () {
                        context.read<AdminTraceBloc>().add(
                          TraceParcelForward(newParcelId),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "  - $amount USDT Parcel to $recipientEmail (${isChange ? 'Change' : 'Recipient'})",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Icon(
                              Icons.track_changes,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Trace",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    final amount = (output['amount'] as num? ?? 0)
                        .toStringAsFixed(10);
                    final coin = (output['coin'] as String? ?? 'N/A')
                        .toUpperCase();
                    final recipientEmail = transaction.toUserEmail;
                    return SelectableText(
                      "  - $amount $coin credited to $recipientEmail",
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(value, maxLines: 1)),
      ],
    );
  }
}
