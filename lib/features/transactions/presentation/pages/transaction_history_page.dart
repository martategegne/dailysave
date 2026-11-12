import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_detail_modal.dart';
import 'add_edit_transaction_page.dart';

/// Complete offline transaction history, search, and filtering interface.
class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<TransactionBloc>().add(TransactionSearchQueryChanged(query));
  }

  void _openFilterDialog(BuildContext context, TransactionState state) {
    TransactionType? selectedType = state.filter.type;
    DateTime? selectedStart = state.filter.startDate;
    DateTime? selectedEnd = state.filter.endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Transactions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<TransactionBloc>().add(
                                const TransactionFilterChanged(TransactionFilter()),
                              );
                          Navigator.pop(bottomSheetCtx);
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transaction Type Filter Chips
                  const Text('Type:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All Types'),
                        selected: selectedType == null,
                        onSelected: (selected) {
                          if (selected) setModalState(() => selectedType = null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Income Only'),
                        selected: selectedType == TransactionType.income,
                        onSelected: (selected) {
                          setModalState(() => selectedType = selected ? TransactionType.income : null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Expense Only'),
                        selected: selectedType == TransactionType.expense,
                        onSelected: (selected) {
                          setModalState(() => selectedType = selected ? TransactionType.expense : null);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Date Ranges
                  const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Today'),
                        onPressed: () {
                          final now = DateTime.now();
                          setModalState(() {
                            selectedStart = DateTime(now.year, now.month, now.day);
                            selectedEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('This Week'),
                        onPressed: () {
                          final now = DateTime.now();
                          final monday = now.subtract(Duration(days: now.weekday - 1));
                          setModalState(() {
                            selectedStart = DateTime(monday.year, monday.month, monday.day);
                            selectedEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('This Month'),
                        onPressed: () {
                          final now = DateTime.now();
                          setModalState(() {
                            selectedStart = DateTime(now.year, now.month, 1);
                            selectedEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply Button
                  FilledButton(
                    onPressed: () {
                      final newFilter = state.filter.copyWith(
                        type: selectedType,
                        startDate: selectedStart,
                        endDate: selectedEnd,
                        clearDates: selectedStart == null,
                      );
                      context.read<TransactionBloc>().add(TransactionFilterChanged(newFilter));
                      Navigator.pop(bottomSheetCtx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Apply Filter'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Filter transactions',
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              final state = context.read<TransactionBloc>().state;
              _openFilterDialog(context, state);
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state.status == TransactionStatus.loading && state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TransactionStatus.failure && state.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.expenseWarning),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load local database.',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(state.errorMessage ?? 'Unknown database error occurred.'),
                  ],
                ),
              ),
            );
          }

          final now = DateTime.now();
          final todayIncome = state.dailyIncome(now);
          final todayExpenses = state.dailyExpenses(now);
          final todaySavings = state.dailySavings(now);
          final transactions = state.filteredTransactions;

          return Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search description, category, or account...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Daily Financial Summary Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkVariant : AppColors.surfaceLightVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryColumn(
                        'Today Income',
                        '+ETB ${(todayIncome / 100).toStringAsFixed(2)}',
                        AppColors.success,
                      ),
                      Container(width: 1, height: 36, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      _buildSummaryColumn(
                        'Today Expenses',
                        '-ETB ${(todayExpenses / 100).toStringAsFixed(2)}',
                        AppColors.expenseWarning,
                      ),
                      Container(width: 1, height: 36, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      _buildSummaryColumn(
                        'Today Savings',
                        '${todaySavings >= 0 ? '+' : '-'}ETB ${(todaySavings.abs() / 100).toStringAsFixed(2)}',
                        todaySavings >= 0 ? AppColors.primaryGreen : AppColors.expenseWarning,
                      ),
                    ],
                  ),
                ),
              ),

              // Active filter indicator if any
              if (!state.filter.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Text('Filter active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<TransactionBloc>().add(
                                const TransactionFilterChanged(TransactionFilter()),
                              );
                        },
                        child: const Text('Clear Filter', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              // Transactions List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 56,
                                color: AppColors.textMutedLight,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No transactions found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                state.filter.isEmpty
                                    ? 'Record your first income or expense.'
                                    : 'No transactions match your active filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isIncome = tx.type == TransactionType.income;
                          final sign = isIncome ? '+' : '-';
                          final color = isIncome ? AppColors.success : AppColors.expenseWarning;

                          return Semantics(
                            label:
                                'Transaction: ${tx.category}, ${tx.description}, $sign${tx.formattedAmount}',
                            child: Card(
                              child: ListTile(
                                onTap: () => TransactionDetailModal.show(context, tx),
                                leading: CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.12),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      tx.category,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${tx.account}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description,
                                      style: TextStyle(
                                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('yyyy-MM-dd • HH:mm').format(tx.date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '$sign${tx.formattedAmount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditTransactionPage(initialType: TransactionType.expense),
            ),
          );
        },
        tooltip: 'Add Transaction',
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryColumn(String title, String amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
