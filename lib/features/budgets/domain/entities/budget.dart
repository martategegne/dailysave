import 'package:equatable/equatable.dart';

enum BudgetPeriod { daily, weekly, monthly, custom }

enum BudgetAlertStatus { normal, approaching75, warning90, exceeded100 }

/// Domain entity representing a spending budget.
/// All monetary calculations use strict integer minor units (cents).
class Budget extends Equatable {
  final String id;
  final String name;
  final int amountInCents;
  final BudgetPeriod period;
  final String? category; // null indicates an overall spending budget
  final DateTime startDate;
  final DateTime? endDate;
  final int warningThresholdPercent; // Default: 75%
  final int dangerThresholdPercent; // Default: 90%
  final int criticalThresholdPercent; // Default: 100%
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.name,
    required this.amountInCents,
    required this.period,
    this.category,
    required this.startDate,
    this.endDate,
    this.warningThresholdPercent = 75,
    this.dangerThresholdPercent = 90,
    this.criticalThresholdPercent = 100,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted budget cap in ETB (e.g. 1500.00).
  String get formattedAmount => (amountInCents / 100).toStringAsFixed(2);

  /// Remaining budget in cents for a given spent amount.
  /// Can be negative if budget is exceeded.
  int remainingCents(int spentCents) => amountInCents - spentCents;

  /// Formatted remaining amount in ETB.
  String formattedRemaining(int spentCents) =>
      (remainingCents(spentCents) / 100).toStringAsFixed(2);

  /// Percentage of budget used, capped at 100+ for overspending.
  double percentageUsed(int spentCents) {
    if (amountInCents <= 0) return 0.0;
    final pct = (spentCents / amountInCents) * 100;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Calculates alert status based on user-customized threshold percentages.
  BudgetAlertStatus alertStatus(int spentCents) {
    final pct = percentageUsed(spentCents);
    if (pct >= criticalThresholdPercent) {
      return BudgetAlertStatus.exceeded100;
    } else if (pct >= dangerThresholdPercent) {
      return BudgetAlertStatus.warning90;
    } else if (pct >= warningThresholdPercent) {
      return BudgetAlertStatus.approaching75;
    }
    return BudgetAlertStatus.normal;
  }

  Budget copyWith({
    String? id,
    String? name,
    int? amountInCents,
    BudgetPeriod? period,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? warningThresholdPercent,
    int? dangerThresholdPercent,
    int? criticalThresholdPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      amountInCents: amountInCents ?? this.amountInCents,
      period: period ?? this.period,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      warningThresholdPercent:
          warningThresholdPercent ?? this.warningThresholdPercent,
      dangerThresholdPercent:
          dangerThresholdPercent ?? this.dangerThresholdPercent,
      criticalThresholdPercent:
          criticalThresholdPercent ?? this.criticalThresholdPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        amountInCents,
        period,
        category,
        startDate,
        endDate,
        warningThresholdPercent,
        dangerThresholdPercent,
        criticalThresholdPercent,
        createdAt,
        updatedAt,
      ];
}
