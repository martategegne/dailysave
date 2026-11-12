import 'package:equatable/equatable.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

enum TransactionStatus {
  initial,
  loading,
  success,
  failure,
}

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<FinancialTransaction> transactions;
  final TransactionFilter filter;
  final String? errorMessage;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.filter = const TransactionFilter(),
    this.errorMessage,
  });

  /// Authoritative calculation of all operating income in minor units (cents).
  /// Excludes transfers between personal accounts and savings deposits/withdrawals.
  int get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amountInCents);
  }

  /// Authoritative calculation of all operating expenses in minor units (cents).
  /// Excludes transfers between personal accounts and savings deposits/withdrawals.
  int get totalExpenses {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amountInCents);
  }

  /// Net Accumulated Savings = Total Operating Income - Total Operating Expenses.
  /// Negative savings are mathematically valid when expenses exceed income.
  int get savings => totalIncome - totalExpenses;

  /// Alias for accumulated net savings.
  int get accumulatedSavings => savings;

  /// Percentage of income saved. Returns 0 if total income is 0.
  double get savingsPercentage {
    if (totalIncome <= 0) return 0.0;
    final rate = (savings / totalIncome) * 100;
    return rate < 0 ? 0.0 : rate;
  }

  /// Returns transactions recorded for the given day using exact local date boundaries.
  List<FinancialTransaction> transactionsForDay(DateTime day) {
    return transactions.where((t) {
      final localDate = t.date.toLocal();
      return localDate.year == day.year &&
          localDate.month == day.month &&
          localDate.day == day.day;
    }).toList();
  }

  /// Operating income recorded for a specific calendar day in local timezone.
  int dailyIncome(DateTime day) {
    return transactionsForDay(day)
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amountInCents);
  }

  /// Operating expenses recorded for a specific calendar day in local timezone.
  int dailyExpenses(DateTime day) {
    return transactionsForDay(day)
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amountInCents);
  }

  /// Core Financial Formula: Daily Savings = Daily Income - Daily Expenses.
  /// Example: 1,000 ETB income and 400 ETB expenses = 600 ETB savings.
  /// Example: 500 ETB income and 700 ETB expenses = -200 ETB savings (valid negative savings).
  int dailySavings(DateTime day) {
    return dailyIncome(day) - dailyExpenses(day);
  }

  /// Filtered transactions view based on the active TransactionFilter.
  List<FinancialTransaction> get filteredTransactions {
    if (filter.isEmpty) return transactions;

    return transactions.where((t) {
      if (filter.startDate != null && t.date.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && t.date.isAfter(filter.endDate!)) {
        return false;
      }
      if (filter.type != null && t.type != filter.type) {
        return false;
      }
      if (filter.category != null &&
          filter.category!.isNotEmpty &&
          t.category.toLowerCase() != filter.category!.toLowerCase()) {
        return false;
      }
      if (filter.account != null &&
          filter.account!.isNotEmpty &&
          t.account.toLowerCase() != filter.account!.toLowerCase()) {
        return false;
      }
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final query = filter.searchQuery!.trim().toLowerCase();
        final matchesDesc = t.description.toLowerCase().contains(query);
        final matchesCat = t.category.toLowerCase().contains(query);
        final matchesNotes = t.notes.toLowerCase().contains(query);
        final matchesAcc = t.account.toLowerCase().contains(query);
        if (!matchesDesc && !matchesCat && !matchesNotes && !matchesAcc) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  TransactionState copyWith({
    TransactionStatus? status,
    List<FinancialTransaction>? transactions,
    TransactionFilter? filter,
    String? errorMessage,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        filter,
        errorMessage,
      ];
}
