import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_parser.dart';
import '../../domain/entities/debt.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Management (ዕዳ እና ብድር)'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'Money Borrowed (የተበደርኩት)'),
            Tab(text: 'Money Lent (ያበደርኩት)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Debt'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<DebtBloc, DebtState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.expenseWarning,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total I Owe (Borrowed)',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(state.totalBorrowedOutstandingCents / 100).toStringAsFixed(2)} ETB',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.expenseWarning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 35, width: 1, color: AppColors.borderLight),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Owed to Me (Lent)',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(state.totalLentOutstandingCents / 100).toStringAsFixed(2)} ETB',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DebtListView(
                      debts: state.borrowedDebts,
                      isBorrowed: true,
                      now: now,
                      onRecordRepayment: (debt) => _showRepaymentDialog(context, debt),
                      onDelete: (debt) => _confirmDelete(context, debt),
                    ),
                    _DebtListView(
                      debts: state.lentDebts,
                      isBorrowed: false,
                      now: now,
                      onRecordRepayment: (debt) => _showRepaymentDialog(context, debt),
                      onDelete: (debt) => _confirmDelete(context, debt),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRepaymentDialog(BuildContext context, Debt debt) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Record Repayment for ${debt.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remaining Balance: ${debt.formattedRemainingAmount} ETB',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Repayment Amount (ETB) *',
                hintText: 'e.g. 500.00',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Telebirr', child: Text('Telebirr')),
                DropdownMenuItem(value: 'CBE', child: Text('CBE')),
              ],
              onChanged: (val) => method = val ?? method,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'e.g. Partial repayment via Telebirr',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final cents = parseEtbToMinorUnits(amountController.text.trim());
              if (cents == null || cents <= 0) return;

              final repayment = DebtRepayment(
                id: const Uuid().v4(),
                debtId: debt.id,
                amountInCents: cents,
                repaymentDate: DateTime.now(),
                paymentMethod: method,
                notes: notesController.text.trim(),
                createdAt: DateTime.now(),
              );

              context.read<DebtBloc>().add(DebtRepaymentSubmitted(repayment));
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirm Repayment'),
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DebtType type = DebtType.borrowed;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record New Debt'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Borrowed (እዳ)')),
                            selected: type == DebtType.borrowed,
                            onSelected: (val) {
                              if (val) setDialogState(() => type = DebtType.borrowed);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Lent (ብድር)')) ,
                            selected: type == DebtType.lent,
                            onSelected: (val) {
                              if (val) setDialogState(() => type = DebtType.lent);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: personController,
                      decoration: InputDecoration(
                        labelText: type == DebtType.borrowed
                            ? 'Lender Name (Lent to you) *'
                            : 'Borrower Name (Borrowed from you) *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Initial Amount (ETB) *',
                        hintText: 'e.g. 2000.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due Date (Optional)'),
                      subtitle: Text(dueDate != null ? DateFormat.yMMMd().format(dueDate!) : 'None set'),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Purpose',
                        hintText: 'e.g. Rent emergency loan',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final cents = parseEtbToMinorUnits(amountController.text.trim());
                    if (cents == null || cents <= 0 || personController.text.trim().isEmpty) {
                      return;
                    }

                    final now = DateTime.now();
                    final debt = Debt(
                      id: const Uuid().v4(),
                      personName: personController.text.trim(),
                      debtType: type,
                      initialAmountInCents: cents,
                      remainingAmountInCents: cents,
                      dueDate: dueDate,
                      description: descController.text.trim(),
                      createdAt: now,
                      updatedAt: now,
                    );

                    context.read<DebtBloc>().add(DebtAdded(debt));
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Debt Record?'),
        content: Text('Are you sure you want to delete the debt record for "${debt.personName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expenseWarning),
            onPressed: () {
              context.read<DebtBloc>().add(DebtDeleted(debt.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DebtListView extends StatelessWidget {
  final List<Debt> debts;
  final bool isBorrowed;
  final DateTime now;
  final Function(Debt) onRecordRepayment;
  final Function(Debt) onDelete;

  const _DebtListView({
    required this.debts,
    required this.isBorrowed,
    required this.now,
    required this.onRecordRepayment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBorrowed ? Icons.handshake_outlined : Icons.account_balance_wallet_outlined,
                size: 50,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                isBorrowed ? 'No borrowed money recorded.' : 'No money lent recorded.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: debts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final debt = debts[index];
        final isOverdue = debt.isOverdue(now);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: debt.isSettled
                  ? AppColors.success
                  : isOverdue
                      ? AppColors.expenseWarning
                      : AppColors.borderLight,
              width: (debt.isSettled || isOverdue) ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      debt.personName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (debt.isSettled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SETTLED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      )
                    else if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.expenseWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.expenseWarning,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'repay') {
                          onRecordRepayment(debt);
                        } else if (action == 'delete') {
                          onDelete(debt);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!debt.isSettled)
                          const PopupMenuItem(
                            value: 'repay',
                            child: Text('Record Repayment'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (debt.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    debt.description,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
                const SizedBox(height: 12),

                // Repayment progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (debt.repaymentPercentage / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      debt.isSettled ? AppColors.success : AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining: ${debt.formattedRemainingAmount} ETB',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: debt.isSettled ? AppColors.success : AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      'Initial: ${debt.formattedInitialAmount} ETB',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    if (debt.dueDate != null)
                      Text(
                        'Due: ${DateFormat.yMMMd().format(debt.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? AppColors.expenseWarning : AppColors.textSecondaryLight,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                  ],
                ),

                if (!debt.isSettled) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Record Repayment'),
                      onPressed: () => onRecordRepayment(debt),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
