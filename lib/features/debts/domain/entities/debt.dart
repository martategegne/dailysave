import 'package:equatable/equatable.dart';

enum DebtType { borrowed, lent }

/// Domain entity representing a repayment installment towards a debt.
class DebtRepayment extends Equatable {
  final String id;
  final String debtId;
  final int amountInCents;
  final DateTime repaymentDate;
  final String paymentMethod;
  final String notes;
  final DateTime createdAt;

  const DebtRepayment({
    required this.id,
    required this.debtId,
    required this.amountInCents,
    required this.repaymentDate,
    this.paymentMethod = 'Cash',
    this.notes = '',
    required this.createdAt,
  });

  String get formattedAmount => (amountInCents / 100).toStringAsFixed(2);

  @override
  List<Object?> get props => [id, debtId, amountInCents, repaymentDate, paymentMethod, notes, createdAt];
}

/// Domain entity representing a personal debt (Money Borrowed or Money Lent).
/// Repayments are strictly tracked and isolated from standard income/expenses.
class Debt extends Equatable {
  final String id;
  final String personName;
  final DebtType debtType;
  final int initialAmountInCents;
  final int remainingAmountInCents;
  final String currency;
  final DateTime? dueDate;
  final String description;
  final bool isSettled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Debt({
    required this.id,
    required this.personName,
    required this.debtType,
    required this.initialAmountInCents,
    required this.remainingAmountInCents,
    this.currency = 'ETB',
    this.dueDate,
    this.description = '',
    this.isSettled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total amount that has been repaid so far.
  int get repaidAmountInCents {
    final diff = initialAmountInCents - remainingAmountInCents;
    return diff > 0 ? diff : 0;
  }

  /// Percentage of debt paid off (0.0% to 100.0%).
  double get repaymentPercentage {
    if (initialAmountInCents <= 0) return 100.0;
    final pct = (repaidAmountInCents / initialAmountInCents) * 100;
    return pct > 100.0 ? 100.0 : double.parse(pct.toStringAsFixed(1));
  }

  /// True if due date is past and debt is not yet settled.
  bool isOverdue(DateTime now) {
    if (isSettled || dueDate == null) return false;
    return now.isAfter(dueDate!);
  }

  String get formattedInitialAmount => (initialAmountInCents / 100).toStringAsFixed(2);
  String get formattedRemainingAmount => (remainingAmountInCents / 100).toStringAsFixed(2);
  String get formattedRepaidAmount => (repaidAmountInCents / 100).toStringAsFixed(2);

  Debt copyWith({
    String? id,
    String? personName,
    DebtType? debtType,
    int? initialAmountInCents,
    int? remainingAmountInCents,
    String? currency,
    DateTime? dueDate,
    String? description,
    bool? isSettled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      debtType: debtType ?? this.debtType,
      initialAmountInCents: initialAmountInCents ?? this.initialAmountInCents,
      remainingAmountInCents: remainingAmountInCents ?? this.remainingAmountInCents,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        personName,
        debtType,
        initialAmountInCents,
        remainingAmountInCents,
        currency,
        dueDate,
        description,
        isSettled,
        createdAt,
        updatedAt,
      ];
}
