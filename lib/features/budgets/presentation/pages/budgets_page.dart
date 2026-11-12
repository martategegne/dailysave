import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_parser.dart';
import '../../domain/entities/budget.dart';
import '../bloc/budget_bloc.dart';
import '../bloc/budget_event.dart';
import '../bloc/budget_state.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management (በጀት)'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBudgetDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<BudgetBloc, BudgetState>(
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
          final items = state.overviewItems;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner if any budget is in warning / danger / exceeded
                if (state.alertItems.isNotEmpty)
                  Card(
                    color: AppColors.expenseWarning.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.expenseWarning),
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.expenseWarning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${state.alertItems.length} budget(s) have reached or exceeded alert thresholds!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.expenseWarning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Text(
                  'Active Budgets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 56,
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No budgets configured yet.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text('Create daily, weekly, or category budgets to stay on track.'),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final budget = item.budget;

                      Color statusColor;
                      String statusBadge;
                      switch (item.alertStatus) {
                        case BudgetAlertStatus.exceeded100:
                          statusColor = AppColors.expenseWarning;
                          statusBadge = 'EXCEEDED';
                          break;
                        case BudgetAlertStatus.warning90:
                          statusColor = Colors.deepOrange;
                          statusBadge = '90% DANGER';
                          break;
                        case BudgetAlertStatus.approaching75:
                          statusColor = Colors.amber.shade800;
                          statusBadge = '75% APPROACHING';
                          break;
                        case BudgetAlertStatus.normal:
                          statusColor = AppColors.primaryGreen;
                          statusBadge = 'ON TRACK';
                          break;
                      }

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: item.alertStatus == BudgetAlertStatus.normal
                                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                                : statusColor,
                            width: item.alertStatus == BudgetAlertStatus.normal ? 1 : 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      budget.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusBadge,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _showAddEditBudgetDialog(context, budgetToEdit: budget);
                                      } else if (action == 'delete') {
                                        _confirmDelete(context, budget);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit Budget')),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${budget.period.name.toUpperCase()} &bull; ${budget.category ?? 'All Categories'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (item.percentageUsed / 100).clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent: ${item.formattedSpent} ETB',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  Text(
                                    'Cap: ${budget.formattedAmount} ETB',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                  ),
                                  Text(
                                    'Remaining: ${item.formattedRemaining} ETB',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddEditBudgetDialog(BuildContext context, {Budget? budgetToEdit}) {
    final nameController = TextEditingController(text: budgetToEdit?.name ?? '');
    final amountController =
        TextEditingController(text: budgetToEdit != null ? budgetToEdit.formattedAmount : '');
    BudgetPeriod period = budgetToEdit?.period ?? BudgetPeriod.monthly;
    String? category = budgetToEdit?.category;
    int warningPct = budgetToEdit?.warningThresholdPercent ?? 75;
    int dangerPct = budgetToEdit?.dangerThresholdPercent ?? 90;

    final categories = [
      'Overall (All Categories)',
      'Food',
      'Transportation',
      'Education',
      'Housing',
      'Electricity',
      'Water',
      'Healthcare',
      'Communication',
      'Internet',
      'Entertainment',
      'Clothing',
      'Shopping',
      'Family support',
      'Business',
      'Personal care',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(budgetToEdit != null ? 'Edit Budget' : 'Create Budget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Budget Name *'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Budget Cap (ETB) *',
                        hintText: 'e.g. 5000.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BudgetPeriod>(
                      initialValue: period,
                      decoration: const InputDecoration(labelText: 'Period'),
                      items: BudgetPeriod.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => period = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category ?? 'Overall (All Categories)',
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          category = (val == 'Overall (All Categories)') ? null : val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: warningPct.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Warning %',
                              helperText: 'Default: 75%',
                            ),
                            onChanged: (val) => warningPct = int.tryParse(val) ?? 75,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: dangerPct.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Danger %',
                              helperText: 'Default: 90%',
                            ),
                            onChanged: (val) => dangerPct = int.tryParse(val) ?? 90,
                          ),
                        ),
                      ],
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
                    if (cents == null || cents <= 0 || nameController.text.trim().isEmpty) {
                      return;
                    }

                    final now = DateTime.now();
                    final b = Budget(
                      id: budgetToEdit?.id ?? const Uuid().v4(),
                      name: nameController.text.trim(),
                      amountInCents: cents,
                      period: period,
                      category: category,
                      startDate: budgetToEdit?.startDate ?? now,
                      warningThresholdPercent: warningPct,
                      dangerThresholdPercent: dangerPct,
                      criticalThresholdPercent: 100,
                      createdAt: budgetToEdit?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (budgetToEdit != null) {
                      context.read<BudgetBloc>().add(BudgetUpdated(b));
                    } else {
                      context.read<BudgetBloc>().add(BudgetAdded(b));
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save Budget'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text('Are you sure you want to delete "${budget.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expenseWarning),
            onPressed: () {
              context.read<BudgetBloc>().add(BudgetDeleted(budget.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
