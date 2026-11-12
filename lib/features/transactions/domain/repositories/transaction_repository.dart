import 'package:equatable/equatable.dart';
import '../entities/financial_transaction.dart';

/// Filter criteria for querying financial transactions.
class TransactionFilter extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? type;
  final String? category;
  final String? account;
  final String? searchQuery;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.category,
    this.account,
    this.searchQuery,
  });

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? category,
    String? account,
    String? searchQuery,
    bool clearDates = false,
  }) {
    return TransactionFilter(
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      type: type ?? this.type,
      category: category ?? this.category,
      account: account ?? this.account,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isEmpty =>
      startDate == null &&
      endDate == null &&
      type == null &&
      category == null &&
      account == null &&
      (searchQuery == null || searchQuery!.trim().isEmpty);

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        type,
        category,
        account,
        searchQuery,
      ];
}

/// Abstract contract for local transaction persistence.
abstract class TransactionRepository {
  Future<List<FinancialTransaction>> getTransactions({TransactionFilter? filter});

  Stream<List<FinancialTransaction>> watchTransactions({TransactionFilter? filter});

  Future<FinancialTransaction?> getTransactionById(String id);

  Future<void> addTransaction(FinancialTransaction transaction);

  Future<void> updateTransaction(FinancialTransaction transaction);

  Future<void> deleteTransaction(String id);
}
