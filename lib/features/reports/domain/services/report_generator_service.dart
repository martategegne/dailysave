import '../../../budgets/domain/entities/budget.dart';
import '../../../goals/domain/entities/financial_goal.dart';
import '../../../transactions/domain/entities/financial_transaction.dart';
import '../entities/financial_report.dart';

class ReportGeneratorService {
  const ReportGeneratorService();

  FinancialReport generate({
    required ReportPeriod period,
    required List<FinancialTransaction> allTransactions,
    required List<Budget> budgets,
    required List<FinancialGoal> goals,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (period) {
      case ReportPeriod.daily:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportPeriod.weekly:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        final sunday = monday.add(const Duration(days: 6));
        end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        break;
      case ReportPeriod.monthly:
        start = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        end = nextMonth.subtract(const Duration(seconds: 1));
        break;
      case ReportPeriod.annual:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case ReportPeriod.custom:
        start = customStart ?? DateTime(now.year, now.month, 1);
        end = customEnd ?? DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }

    final periodTransactions = allTransactions.where((t) {
      return !t.date.isBefore(start) && !t.date.isAfter(end);
    }).toList();

    final incomeCents = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amountInCents);

    final expenseCents = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amountInCents);

    final netSavingsCents = incomeCents - expenseCents;

    double rate = 0.0;
    if (incomeCents > 0) {
      final calculatedRate = (netSavingsCents / incomeCents) * 100;
      rate = calculatedRate < 0 ? 0.0 : double.parse(calculatedRate.toStringAsFixed(1));
    }

    // Category spending breakdown
    final categoryMap = <String, int>{};
    for (final tx in periodTransactions) {
      if (tx.type == TransactionType.expense) {
        categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amountInCents;
      }
    }

    final categoryItems = categoryMap.entries.map((entry) {
      final pct = expenseCents > 0
          ? double.parse(((entry.value / expenseCents) * 100).toStringAsFixed(1))
          : 0.0;
      return CategorySpendingItem(
        category: entry.key,
        amountInCents: entry.value,
        percentageOfTotal: pct,
      );
    }).toList()
      ..sort((a, b) => b.amountInCents.compareTo(a.amountInCents));

    return FinancialReport(
      period: period,
      startDate: start,
      endDate: end,
      totalIncomeCents: incomeCents,
      totalExpenseCents: expenseCents,
      netSavingsCents: netSavingsCents,
      savingsRate: rate,
      categoryBreakdown: categoryItems,
      budgets: budgets,
      goals: goals,
      transactions: periodTransactions,
    );
  }
}
