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

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _pageTitles[_selectedIndex],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () {
                          context.read<ProfileBloc>().add(LogoutEvent());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _adminPages,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.history_edu,
                  label: 'Trace',
                  index: 0,
                  isSelected: _selectedIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.note_alt_outlined,
                  label: 'Digital Notes',
                  index: 1,
                  isSelected: _selectedIndex == 1,
                ),
              ],
            ),
          ),
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Card
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
              child: const TransactionSearchBox(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<AdminTraceBloc, AdminTraceState>(
                builder: (context, state) {
                  if (state is AdminTraceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AdminTraceLoaded) {
                    if (state.transactions.isEmpty) {
                      return Center(
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
                          child: const Text(
                            "No transactions found.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      );
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
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<AdminTraceBloc>()
                                  .add(LoadRecentTransactions()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Show Recent Transactions"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Center(
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
                      child: const Text(
                        "Search for a transaction ID or pull to refresh.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
        prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
        ),
        title: Text(
          amountString,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          formattedDate,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  "Txn ID: ${transaction.transactionId}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                _buildTraceRow('From:', transaction.fromUserEmail),
                const SizedBox(height: 8),
                _buildTraceRow('To:', transaction.toUserEmail),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Inputs (Funds Consumed):",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...transaction.inputs.map((input) {
                        if (input.containsKey('parcelId')) {
                          final amount = (input['amount'] as num? ?? 0)
                              .toStringAsFixed(2);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              "• From ${transaction.fromUserEmail} [$amount USDT Parcel]",
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        } else {
                          final amount = (input['amount'] as num? ?? 0)
                              .toStringAsFixed(10);
                          final coin = (input['coin'] as String? ?? 'N/A')
                              .toUpperCase();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              "• From ${transaction.fromUserEmail} [$amount $coin Balance]",
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Outputs (Funds Created):",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...transaction.outputs.map((output) {
                        if (output.containsKey('newParcelId')) {
                          final bool isChange =
                              output['recipientUserId'] ==
                              transaction.fromUserId;
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
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "• $amount USDT Parcel to $recipientEmail (${isChange ? 'Change' : 'Recipient'})",
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
                                      fontWeight: FontWeight.w500,
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              "• $amount $coin credited to $recipientEmail",
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
