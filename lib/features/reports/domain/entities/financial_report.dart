import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget.dart';
import '../../../goals/domain/entities/financial_goal.dart';
import '../../../transactions/domain/entities/financial_transaction.dart';

enum ReportPeriod { daily, weekly, monthly, annual, custom }

/// Category spending aggregation entry.
class CategorySpendingItem extends Equatable {
  final String category;
  final int amountInCents;
  final double percentageOfTotal;

  const CategorySpendingItem({
    required this.category,
    required this.amountInCents,
    required this.percentageOfTotal,
  });

  String get formattedAmount => (amountInCents / 100).toStringAsFixed(2);

  @override
  List<Object?> get props => [category, amountInCents, percentageOfTotal];
}

/// Comprehensive financial report entity covering income, expenses, savings,
/// category breakdowns, budget adherence, and goal progress.
class FinancialReport extends Equatable {
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final int totalIncomeCents;
  final int totalExpenseCents;
  final int netSavingsCents;
  final double savingsRate;
  final List<CategorySpendingItem> categoryBreakdown;
  final List<Budget> budgets;
  final List<FinancialGoal> goals;
  final List<FinancialTransaction> transactions;

  const FinancialReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.netSavingsCents,
    required this.savingsRate,
    required this.categoryBreakdown,
    required this.budgets,
    required this.goals,
    required this.transactions,
  });

  String get formattedTotalIncome => (totalIncomeCents / 100).toStringAsFixed(2);
  String get formattedTotalExpense => (totalExpenseCents / 100).toStringAsFixed(2);
  String get formattedNetSavings => (netSavingsCents / 100).toStringAsFixed(2);

  /// Generates a standardized, sanitized CSV representation of this report.
  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('DAILYSave Financial Report');
    buffer.writeln('Period,${period.name}');
    buffer.writeln('Start Date,${startDate.toIso8601String().split('T').first}');
    buffer.writeln('End Date,${endDate.toIso8601String().split('T').first}');
    buffer.writeln('');

    buffer.writeln('Financial Summary (ETB)');
    buffer.writeln('Metric,Amount (ETB)');
    buffer.writeln('Total Operating Income,$formattedTotalIncome');
    buffer.writeln('Total Operating Expenses,$formattedTotalExpense');
    buffer.writeln('Net Savings,$formattedNetSavings');
    buffer.writeln('Savings Rate,${savingsRate.toStringAsFixed(1)}%');
    buffer.writeln('');

    buffer.writeln('Category Spending Breakdown');
    buffer.writeln('Category,Amount (ETB),Percentage');
    for (final item in categoryBreakdown) {
      buffer.writeln('"${item.category}",${item.formattedAmount},${item.percentageOfTotal.toStringAsFixed(1)}%');
    }
    buffer.writeln('');

    buffer.writeln('Transaction Details');
    buffer.writeln('Date,Type,Category,Description,Amount (ETB),Payment Method,Account');
    for (final tx in transactions) {
      final dateStr = tx.date.toIso8601String().split('T').first;
      final descEscaped = tx.description.replaceAll('"', '""');
      buffer.writeln('$dateStr,${tx.type.name},"${tx.category}","$descEscaped",${tx.formattedAmount},"${tx.paymentMethod}","${tx.account}"');
    }

    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        period,
        startDate,
        endDate,
        totalIncomeCents,
        totalExpenseCents,
        netSavingsCents,
        savingsRate,
        categoryBreakdown,
        budgets,
        goals,
        transactions,
      ];
}
