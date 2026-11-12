import 'package:equatable/equatable.dart';

/// Domain entity representing a contribution towards a goal.
class GoalContribution extends Equatable {
  final String id;
  final String goalId;
  final int amountInCents;
  final DateTime date;
  final String notes;
  final String sourceAccount;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amountInCents,
    required this.date,
    this.notes = '',
    this.sourceAccount = 'Cash Wallet',
  });

  String get formattedAmount => (amountInCents / 100).toStringAsFixed(2);

  @override
  List<Object?> get props => [id, goalId, amountInCents, date, notes, sourceAccount];
}

/// Domain entity representing a savings or purchasing goal.
class FinancialGoal extends Equatable {
  final String id;
  final String name;
  final int targetAmountInCents;
  final int currentAmountInCents;
  final String currency;
  final DateTime deadline;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialGoal({
    required this.id,
    required this.name,
    required this.targetAmountInCents,
    this.currentAmountInCents = 0,
    this.currency = 'ETB',
    required this.deadline,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Remaining amount needed to reach target (cannot be less than 0).
  int get remainingAmountInCents {
    final diff = targetAmountInCents - currentAmountInCents;
    return diff > 0 ? diff : 0;
  }

  /// Completion percentage from 0.0% to 100.0%.
  double get progressPercentage {
    if (targetAmountInCents <= 0) return 100.0;
    final pct = (currentAmountInCents / targetAmountInCents) * 100;
    return pct > 100.0 ? 100.0 : double.parse(pct.toStringAsFixed(1));
  }

  /// Whether the target has been fulfilled.
  bool get isCompleted => currentAmountInCents >= targetAmountInCents;

  /// Check if goal is past deadline and not completed.
  bool isOverdue(DateTime now) => now.isAfter(deadline) && !isCompleted;

  String get formattedTargetAmount => (targetAmountInCents / 100).toStringAsFixed(2);
  String get formattedCurrentAmount => (currentAmountInCents / 100).toStringAsFixed(2);
  String get formattedRemainingAmount => (remainingAmountInCents / 100).toStringAsFixed(2);

  FinancialGoal copyWith({
    String? id,
    String? name,
    int? targetAmountInCents,
    int? currentAmountInCents,
    String? currency,
    DateTime? deadline,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountInCents: targetAmountInCents ?? this.targetAmountInCents,
      currentAmountInCents: currentAmountInCents ?? this.currentAmountInCents,
      currency: currency ?? this.currency,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmountInCents,
        currentAmountInCents,
        currency,
        deadline,
        description,
        createdAt,
        updatedAt,
      ];
}
