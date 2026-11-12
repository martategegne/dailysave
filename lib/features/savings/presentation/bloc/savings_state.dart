import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/financial_transaction.dart';

enum SavingsStatus { initial, loading, success, failure }

class SavingsGrowthPoint extends Equatable {
  final String label; // e.g. "Nov", "Dec"
  final DateTime date;
  final int netSavingsCents;
  final int actualDepositedCents;

  const SavingsGrowthPoint({
    required this.label,
    required this.date,
    required this.netSavingsCents,
    required this.actualDepositedCents,
  });

  @override
  List<Object?> get props => [label, date, netSavingsCents, actualDepositedCents];
}

class SavingsState extends Equatable {
  final SavingsStatus status;
  final List<FinancialTransaction> transactions;
  final String? errorMessage;

  const SavingsState({
    this.status = SavingsStatus.initial,
    this.transactions = const [],
    this.errorMessage,
  });

  // --- 1. CALCULATED OPERATING METRICS (Income minus Expenses) ---

  int get totalOperatingIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amountInCents);

  int get totalOperatingExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amountInCents);

  /// Net Accumulated Savings = Operating Income - Operating Expenses.
  /// Valid negative savings occur if expenses exceed income.
  int get accumulatedNetSavings => totalOperatingIncome - totalOperatingExpenses;

  /// Percentage of income retained (Savings Rate).
  double get savingsRate {
    if (totalOperatingIncome <= 0) return 0.0;
    final rate = (accumulatedNetSavings / totalOperatingIncome) * 100;
    return rate < 0 ? 0.0 : double.parse(rate.toStringAsFixed(1));
  }

  /// Net savings for a specific calendar day.
  int dailySavings(DateTime day) {
    final inc = transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .fold(0, (sum, t) => sum + t.amountInCents);

    final exp = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .fold(0, (sum, t) => sum + t.amountInCents);

    return inc - exp;
  }

  /// Net savings for the calendar week enclosing [date] (Monday to Sunday).
  int weeklySavings(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final start = DateTime(monday.year, monday.month, monday.day);
    final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

    final inc = transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amountInCents);

    final exp = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amountInCents);

    return inc - exp;
  }

  /// Net savings for a calendar month.
  int monthlySavings(DateTime date) {
    final inc = transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == date.year &&
            t.date.month == date.month)
        .fold(0, (sum, t) => sum + t.amountInCents);

    final exp = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == date.year &&
            t.date.month == date.month)
        .fold(0, (sum, t) => sum + t.amountInCents);

    return inc - exp;
  }

  /// Net savings for a calendar year.
  int annualSavings(int year) {
    final inc = transactions
        .where((t) => t.type == TransactionType.income && t.date.year == year)
        .fold(0, (sum, t) => sum + t.amountInCents);

    final exp = transactions
        .where((t) => t.type == TransactionType.expense && t.date.year == year)
        .fold(0, (sum, t) => sum + t.amountInCents);

    return inc - exp;
  }

  // --- 2. ACTUAL SAVINGS ACCOUNT BALANCES (Deposits & Withdrawals) ---

  /// Actual money deposited into dedicated savings accounts.
  int get actualSavingsDepositsTotal => transactions
      .where((t) => t.type == TransactionType.savingsDeposit)
      .fold(0, (sum, t) => sum + t.amountInCents);

  /// Actual money withdrawn from dedicated savings accounts.
  int get actualSavingsWithdrawalsTotal => transactions
      .where((t) => t.type == TransactionType.savingsWithdrawal)
      .fold(0, (sum, t) => sum + t.amountInCents);

  /// Actual balance residing in savings accounts.
  int get actualSavingsAccountBalance =>
      actualSavingsDepositsTotal - actualSavingsWithdrawalsTotal;

  /// Dedicated list of savings transactions (deposits & withdrawals).
  List<FinancialTransaction> get savingsAccountHistory => transactions
      .where((t) =>
          t.type == TransactionType.savingsDeposit ||
          t.type == TransactionType.savingsWithdrawal)
      .toList();

  /// Monthly growth points for the last 6 months.
  List<SavingsGrowthPoint> get growthPoints {
    final now = DateTime.now();
    final points = <SavingsGrowthPoint>[];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    for (int i = 5; i >= 0; i--) {
      // Step back i months
      final target = DateTime(now.year, now.month - i, 1);
      final net = monthlySavings(target);
      final dep = transactions
          .where((t) =>
              t.type == TransactionType.savingsDeposit &&
              t.date.year == target.year &&
              t.date.month == target.month)
          .fold(0, (sum, t) => sum + t.amountInCents);

      points.add(SavingsGrowthPoint(
        label: '${monthNames[target.month - 1]} ${target.year % 100}',
        date: target,
        netSavingsCents: net,
        actualDepositedCents: dep,
      ));
    }
    return points;
  }

  SavingsState copyWith({
    SavingsStatus? status,
    List<FinancialTransaction>? transactions,
    String? errorMessage,
  }) {
    return SavingsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, errorMessage];
}
