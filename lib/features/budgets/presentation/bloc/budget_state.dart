import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/financial_transaction.dart';
import '../../domain/entities/budget.dart';

enum BudgetStatus { initial, loading, success, failure }

class BudgetOverviewItem extends Equatable {
  final Budget budget;
  final int spentInCents;
  final int remainingInCents;
  final double percentageUsed;
  final BudgetAlertStatus alertStatus;

  const BudgetOverviewItem({
    required this.budget,
    required this.spentInCents,
    required this.remainingInCents,
    required this.percentageUsed,
    required this.alertStatus,
  });

  String get formattedSpent => (spentInCents / 100).toStringAsFixed(2);
  String get formattedRemaining => (remainingInCents / 100).toStringAsFixed(2);

  @override
  List<Object?> get props => [
        budget,
        spentInCents,
        remainingInCents,
        percentageUsed,
        alertStatus,
      ];
}

class BudgetState extends Equatable {
  final BudgetStatus status;
  final List<Budget> budgets;
  final List<FinancialTransaction> transactions;
  final String? errorMessage;

  const BudgetState({
    this.status = BudgetStatus.initial,
    this.budgets = const [],
    this.transactions = const [],
    this.errorMessage,
  });

  /// Computes spent amount in minor units for a specific budget based on its period and category.
  int spentForBudget(Budget budget) {
    final now = DateTime.now();
    DateTime windowStart;
    DateTime windowEnd;

    switch (budget.period) {
      case BudgetPeriod.daily:
        windowStart = DateTime(now.year, now.month, now.day);
        windowEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case BudgetPeriod.weekly:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        windowStart = DateTime(monday.year, monday.month, monday.day);
        final sunday = monday.add(const Duration(days: 6));
        windowEnd = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        break;
      case BudgetPeriod.monthly:
        windowStart = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        windowEnd = nextMonth.subtract(const Duration(seconds: 1));
        break;
      case BudgetPeriod.custom:
        windowStart = budget.startDate;
        windowEnd = budget.endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }

    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            (budget.category == null ||
                budget.category!.isEmpty ||
                t.category.toLowerCase() == budget.category!.toLowerCase()) &&
            !t.date.isBefore(windowStart) &&
            !t.date.isAfter(windowEnd))
        .fold(0, (sum, t) => sum + t.amountInCents);
  }

  /// Returns detailed budget overviews with current spending, remaining amounts, and alert thresholds.
  List<BudgetOverviewItem> get overviewItems {
    return budgets.map((b) {
      final spent = spentForBudget(b);
      final remaining = b.remainingCents(spent);
      final pct = b.percentageUsed(spent);
      final status = b.alertStatus(spent);

      return BudgetOverviewItem(
        budget: b,
        spentInCents: spent,
        remainingInCents: remaining,
        percentageUsed: pct,
        alertStatus: status,
      );
    }).toList();
  }

  /// List of items that have triggered warnings (>=75%, >=90%, or >=100%).
  List<BudgetOverviewItem> get alertItems =>
      overviewItems.where((i) => i.alertStatus != BudgetAlertStatus.normal).toList();

  BudgetState copyWith({
    BudgetStatus? status,
    List<Budget>? budgets,
    List<FinancialTransaction>? transactions,
    String? errorMessage,
  }) {
    return BudgetState(
      status: status ?? this.status,
      budgets: budgets ?? this.budgets,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, budgets, transactions, errorMessage];
}
