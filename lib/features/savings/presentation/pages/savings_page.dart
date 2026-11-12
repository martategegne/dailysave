import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_parser.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import '../bloc/savings_state.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Management (ቁጠባ)'),
        elevation: 0,
      ),
      body: BlocConsumer<SavingsBloc, SavingsState>(
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
          final now = DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Buttons: Deposit & Withdrawal
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Savings Deposit (ገቢ)'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showDepositDialog(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Withdraw (ወጪ)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkNavy,
                          side: const BorderSide(color: AppColors.darkNavy),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showWithdrawalDialog(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Core Distinction Banner: Net Savings vs Savings Account
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
                          'Savings Sovereignty Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'DailySave strictly distinguishes calculated Net Savings (Operating Income minus Operating Expenses) from Actual Money Deposited into bank savings reserves.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricItem(
                                title: 'Accumulated Net Savings',
                                value: '${(state.accumulatedNetSavings / 100).toStringAsFixed(2)} ETB',
                                color: state.accumulatedNetSavings >= 0
                                    ? AppColors.primaryGreen
                                    : AppColors.expenseWarning,
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                            Expanded(
                              child: _MetricItem(
                                title: 'Actual Savings Reserve',
                                value: '${(state.actualSavingsAccountBalance / 100).toStringAsFixed(2)} ETB',
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                            Expanded(
                              child: _MetricItem(
                                title: 'Savings Rate',
                                value: '${state.savingsRate.toStringAsFixed(1)}%',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Multi-Period Calculated Savings Breakdown
                const Text(
                  'Multi-Period Net Savings Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _PeriodCard(
                      title: 'Today',
                      amountInCents: state.dailySavings(now),
                    ),
                    _PeriodCard(
                      title: 'This Week',
                      amountInCents: state.weeklySavings(now),
                    ),
                    _PeriodCard(
                      title: 'This Month',
                      amountInCents: state.monthlySavings(now),
                    ),
                    _PeriodCard(
                      title: 'This Year (${now.year})',
                      amountInCents: state.annualSavings(now.year),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 6-Month Savings Growth Chart (Accessible Bar Representation)
                const Text(
                  '6-Month Savings Growth Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Comparing Net Operational Savings against Actual Account Deposits.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                _GrowthTrendWidget(growthPoints: state.growthPoints),
                const SizedBox(height: 28),

                // Dedicated Savings Account Activity
                const Text(
                  'Savings Reserve History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.savingsAccountHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No savings account deposits or withdrawals recorded yet.',
                        style: TextStyle(
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.savingsAccountHistory.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = state.savingsAccountHistory[index];
                      final isDeposit = tx.type.name == 'savingsDeposit';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDeposit
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.expenseWarning.withValues(alpha: 0.15),
                          child: Icon(
                            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isDeposit ? AppColors.success : AppColors.expenseWarning,
                            size: 20,
                          ),
                        ),
                        title: Text(tx.description),
                        subtitle: Text(
                          '${tx.date.toIso8601String().split('T').first} &bull; ${tx.account}',
                        ),
                        trailing: Text(
                          '${isDeposit ? '+' : '-'}${tx.formattedAmount} ETB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDeposit ? AppColors.success : AppColors.expenseWarning,
                            fontSize: 15,
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

  void _showDepositDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String savingsAccount = 'Emergency Savings Reserve';
    String sourceAccount = 'Telebirr';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deposit into Savings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Deposit Amount (ETB) *',
                    hintText: 'e.g. 1500.00',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: sourceAccount,
                  decoration: const InputDecoration(labelText: 'From Account (Source)'),
                  items: const [
                    DropdownMenuItem(value: 'Cash Wallet', child: Text('Cash Wallet')),
                    DropdownMenuItem(value: 'Telebirr', child: Text('Telebirr')),
                    DropdownMenuItem(value: 'Commercial Bank of Ethiopia (CBE)', child: Text('CBE')),
                  ],
                  onChanged: (val) => sourceAccount = val ?? sourceAccount,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: savingsAccount,
                  decoration: const InputDecoration(labelText: 'To Savings Account'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Emergency Savings Reserve',
                      child: Text('Emergency Savings Reserve'),
                    ),
                    DropdownMenuItem(
                      value: 'CBE Savings Account',
                      child: Text('CBE Savings Account'),
                    ),
                  ],
                  onChanged: (val) => savingsAccount = val ?? savingsAccount,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'e.g. Monthly emergency reserve deposit',
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
                final cents = parseEtbToMinorUnits(amountController.text);
                if (cents == null || cents <= 0) return;

                context.read<SavingsBloc>().add(
                      SavingsDepositSubmitted(
                        amountInCents: cents,
                        savingsAccount: savingsAccount,
                        sourceAccount: sourceAccount,
                        description: descController.text.trim(),
                        date: DateTime.now(),
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Confirm Deposit'),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawalDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String savingsAccount = 'Emergency Savings Reserve';
    String targetAccount = 'Cash Wallet';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Withdraw from Savings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Withdrawal Amount (ETB) *',
                    hintText: 'e.g. 500.00',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: savingsAccount,
                  decoration: const InputDecoration(labelText: 'From Savings Account'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Emergency Savings Reserve',
                      child: Text('Emergency Savings Reserve'),
                    ),
                    DropdownMenuItem(
                      value: 'CBE Savings Account',
                      child: Text('CBE Savings Account'),
                    ),
                  ],
                  onChanged: (val) => savingsAccount = val ?? savingsAccount,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: targetAccount,
                  decoration: const InputDecoration(labelText: 'Transfer To Account'),
                  items: const [
                    DropdownMenuItem(value: 'Cash Wallet', child: Text('Cash Wallet')),
                    DropdownMenuItem(value: 'Telebirr', child: Text('Telebirr')),
                    DropdownMenuItem(value: 'Commercial Bank of Ethiopia (CBE)', child: Text('CBE')),
                  ],
                  onChanged: (val) => targetAccount = val ?? targetAccount,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Withdrawal',
                    hintText: 'e.g. Medical emergency payment',
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
                final cents = parseEtbToMinorUnits(amountController.text);
                if (cents == null || cents <= 0) return;

                context.read<SavingsBloc>().add(
                      SavingsWithdrawalSubmitted(
                        amountInCents: cents,
                        savingsAccount: savingsAccount,
                        targetAccount: targetAccount,
                        description: descController.text.trim(),
                        date: DateTime.now(),
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Confirm Withdrawal'),
            ),
          ],
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String title;
  final int amountInCents;

  const _PeriodCard({
    required this.title,
    required this.amountInCents,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amountInCents < 0;
    final color = isNegative ? AppColors.expenseWarning : AppColors.primaryGreen;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 6),
            Text(
              '${(amountInCents / 100).toStringAsFixed(2)} ETB',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthTrendWidget extends StatelessWidget {
  final List<SavingsGrowthPoint> growthPoints;

  const _GrowthTrendWidget({required this.growthPoints});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Semantics alternative for screen readers
            Semantics(
              label: '6 month savings trend data summary',
              child: const SizedBox.shrink(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: growthPoints.map((point) {
                final netEtb = point.netSavingsCents / 100;
                final barHeight = (netEtb.abs() / 100).clamp(15.0, 120.0);
                final isPositive = netEtb >= 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      netEtb.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.primaryGreen : AppColors.expenseWarning,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppColors.primaryGreen.withValues(alpha: 0.8)
                            : AppColors.expenseWarning.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      point.label,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
