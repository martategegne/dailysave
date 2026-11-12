import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_parser.dart';
import '../../domain/entities/financial_goal.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals (ግብ)'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditGoalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Progress Summary Banner
                Card(
                  elevation: 0,
                  color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Goals Milestone',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (state.aggregateProgressPercentage / 100).clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved: ${(state.totalSavedCents / 100).toStringAsFixed(2)} ETB',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Target: ${(state.totalTargetCents / 100).toStringAsFixed(2)} ETB',
                              style: const TextStyle(color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              '${state.aggregateProgressPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Your Goals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (state.goals.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 56,
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No financial goals created yet.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text('Set a goal to buy a laptop, emergency reserve, or business startup.'),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.goals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final goal = state.goals[index];
                      final isOverdue = goal.isOverdue(now);
                      final deadlineStr = DateFormat.yMMMd().format(goal.deadline);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: goal.isCompleted
                                ? AppColors.success
                                : isOverdue
                                    ? AppColors.expenseWarning
                                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: (goal.isCompleted || isOverdue) ? 1.5 : 1,
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (goal.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            goal.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.textMutedDark
                                                  : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (goal.isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'COMPLETED',
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
                                      if (action == 'contribute') {
                                        _showContributeDialog(context, goal);
                                      } else if (action == 'edit') {
                                        _showAddEditGoalDialog(context, goalToEdit: goal);
                                      } else if (action == 'delete') {
                                        _confirmDelete(context, goal);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'contribute',
                                        child: Text('Add Contribution'),
                                      ),
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (goal.progressPercentage / 100).clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor:
                                      isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    goal.isCompleted ? AppColors.success : AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Saved: ${goal.formattedCurrentAmount} ETB (${goal.progressPercentage.toStringAsFixed(1)}%)',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Target: ${goal.formattedTargetAmount} ETB',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining: ${goal.formattedRemainingAmount} ETB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: goal.isCompleted
                                          ? AppColors.success
                                          : AppColors.darkNavy,
                                    ),
                                  ),
                                  Text(
                                    'Deadline: $deadlineStr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOverdue
                                          ? AppColors.expenseWarning
                                          : AppColors.textSecondaryLight,
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              if (!goal.isCompleted)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonalIcon(
                                    icon: const Icon(Icons.savings_outlined, size: 18),
                                    label: const Text('Contribute'),
                                    onPressed: () => _showContributeDialog(context, goal),
                                  ),
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

  void _showContributeDialog(BuildContext context, FinancialGoal goal) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String sourceAccount = 'Cash Wallet';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Contribute to "${goal.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Contribution Amount (ETB) *',
                hintText: 'e.g. 1000.00',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: sourceAccount,
              decoration: const InputDecoration(labelText: 'From Account'),
              items: const [
                DropdownMenuItem(value: 'Cash Wallet', child: Text('Cash Wallet')),
                DropdownMenuItem(value: 'Telebirr', child: Text('Telebirr')),
                DropdownMenuItem(value: 'Commercial Bank of Ethiopia (CBE)', child: Text('CBE')),
              ],
              onChanged: (val) => sourceAccount = val ?? sourceAccount,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'e.g. Freelance bonus contribution',
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

              final contrib = GoalContribution(
                id: const Uuid().v4(),
                goalId: goal.id,
                amountInCents: cents,
                date: DateTime.now(),
                notes: notesController.text.trim(),
                sourceAccount: sourceAccount,
              );

              context.read<GoalBloc>().add(GoalContributionSubmitted(contrib));
              Navigator.pop(dialogContext);
            },
            child: const Text('Record Contribution'),
          ),
        ],
      ),
    );
  }

  void _showAddEditGoalDialog(BuildContext context, {FinancialGoal? goalToEdit}) {
    final nameController = TextEditingController(text: goalToEdit?.name ?? '');
    final targetController = TextEditingController(
      text: goalToEdit != null ? goalToEdit.formattedTargetAmount : '',
    );
    final descController = TextEditingController(text: goalToEdit?.description ?? '');
    DateTime deadline =
        goalToEdit?.deadline ?? DateTime.now().add(const Duration(days: 90));

    final presetExamples = [
      'Buy a laptop',
      'Pay university expenses',
      'Build emergency savings',
      'Start a business',
      'Save for education',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(goalToEdit != null ? 'Edit Goal' : 'Create Financial Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Goal Name *'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: presetExamples
                          .map((preset) => ActionChip(
                                label: Text(preset, style: const TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setDialogState(() => nameController.text = preset);
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Target Amount (ETB) *',
                        hintText: 'e.g. 50000.00',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Target Deadline'),
                      subtitle: Text(DateFormat.yMMMd().format(deadline)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setDialogState(() => deadline = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g. 6-month buffer for living costs',
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
                    final cents = parseEtbToMinorUnits(targetController.text.trim());
                    if (cents == null || cents <= 0 || nameController.text.trim().isEmpty) {
                      return;
                    }

                    final now = DateTime.now();
                    final g = FinancialGoal(
                      id: goalToEdit?.id ?? const Uuid().v4(),
                      name: nameController.text.trim(),
                      targetAmountInCents: cents,
                      currentAmountInCents: goalToEdit?.currentAmountInCents ?? 0,
                      currency: 'ETB',
                      deadline: deadline,
                      description: descController.text.trim(),
                      createdAt: goalToEdit?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (goalToEdit != null) {
                      context.read<GoalBloc>().add(GoalUpdated(g));
                    } else {
                      context.read<GoalBloc>().add(GoalAdded(g));
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expenseWarning),
            onPressed: () {
              context.read<GoalBloc>().add(GoalDeleted(goal.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
