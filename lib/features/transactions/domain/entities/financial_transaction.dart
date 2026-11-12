import 'package:equatable/equatable.dart';

/// Distinct types of financial operations supported by DailySave.
/// Note: Transfers between personal accounts and savings deposits/withdrawals
/// are explicitly separated from everyday operating Income and Expenses.
enum TransactionType {
  income,
  expense,
  transfer,
  savingsDeposit,
  savingsWithdrawal;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.savingsDeposit:
        return 'Savings Deposit';
      case TransactionType.savingsWithdrawal:
        return 'Savings Withdrawal';
    }
  }

  static TransactionType fromString(String val) {
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}

/// Domain entity representing a complete financial transaction record.
/// Uses minor units (int amountInCents) to avoid floating-point inaccuracies.
class FinancialTransaction extends Equatable {
  final String id;
  final int amountInCents;
  final TransactionType type;
  final String currency;
  final String category;
  final String description;
  final DateTime date;
  final String paymentMethod;
  final String account;
  final String notes;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialTransaction({
    required this.id,
    required this.amountInCents,
    required this.type,
    this.currency = 'ETB',
    required this.category,
    required this.description,
    required this.date,
    this.paymentMethod = 'Cash',
    this.account = 'Cash Wallet',
    this.notes = '',
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted monetary amount in standard ETB notation (e.g. "ETB 1,250.00").
  String get formattedAmount {
    final double amount = amountInCents / 100;
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  FinancialTransaction copyWith({
    String? id,
    int? amountInCents,
    TransactionType? type,
    String? currency,
    String? category,
    String? description,
    DateTime? date,
    String? paymentMethod,
    String? account,
    String? notes,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      amountInCents: amountInCents ?? this.amountInCents,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      account: account ?? this.account,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amountInCents,
        type,
        currency,
        category,
        description,
        date,
        paymentMethod,
        account,
        notes,
        receiptPath,
        createdAt,
        updatedAt,
      ];
}
