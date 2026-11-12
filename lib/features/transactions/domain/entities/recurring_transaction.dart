import 'package:equatable/equatable.dart';

class RecurringTransaction extends Equatable {
  final String id;
  final int amountInCents;
  final String type; // 'income' or 'expense'
  final String currency;
  final String category;
  final String description;
  final String recurrenceInterval; // 'daily', 'weekly', 'monthly', 'annual'
  final DateTime nextExecutionDate;
  final String account;
  final bool requiresReview;
  final bool isActive;

  const RecurringTransaction({
    required this.id,
    required this.amountInCents,
    required this.type,
    this.currency = 'ETB',
    required this.category,
    required this.description,
    required this.recurrenceInterval,
    required this.nextExecutionDate,
    this.account = 'Cash Wallet',
    this.requiresReview = true,
    this.isActive = true,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      amountInCents: int.parse(json['amount_cents'].toString()),
      type: json['type'] as String,
      currency: (json['currency'] ?? 'ETB') as String,
      category: json['category'] as String,
      description: (json['description'] ?? '') as String,
      recurrenceInterval: json['recurrence_interval'] as String,
      nextExecutionDate: DateTime.parse(json['next_execution_date'] as String),
      account: (json['account'] ?? 'Cash Wallet') as String,
      requiresReview: json['requires_review'] == true,
      isActive: json['is_active'] != false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amountInCents,
        type,
        currency,
        category,
        recurrenceInterval,
        nextExecutionDate,
        isActive,
      ];
}
