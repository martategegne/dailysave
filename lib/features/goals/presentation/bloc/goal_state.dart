import 'package:equatable/equatable.dart';

import '../../domain/entities/financial_goal.dart';

enum GoalStatus { initial, loading, success, failure }

class GoalState extends Equatable {
  final GoalStatus status;
  final List<FinancialGoal> goals;
  final String? errorMessage;

  const GoalState({
    this.status = GoalStatus.initial,
    this.goals = const [],
    this.errorMessage,
  });

  /// Total target sum in minor units across all active goals.
  int get totalTargetCents =>
      goals.fold(0, (sum, g) => sum + g.targetAmountInCents);

  /// Total saved sum in minor units across all goals.
  int get totalSavedCents =>
      goals.fold(0, (sum, g) => sum + g.currentAmountInCents);

  /// Overall aggregate progress percentage.
  double get aggregateProgressPercentage {
    if (totalTargetCents <= 0) return 0.0;
    final pct = (totalSavedCents / totalTargetCents) * 100;
    return pct > 100.0 ? 100.0 : double.parse(pct.toStringAsFixed(1));
  }

  /// Number of completed goals.
  int get completedGoalsCount => goals.where((g) => g.isCompleted).length;

  /// Active in-progress goals.
  List<FinancialGoal> get inProgressGoals =>
      goals.where((g) => !g.isCompleted).toList();

  GoalState copyWith({
    GoalStatus? status,
    List<FinancialGoal>? goals,
    String? errorMessage,
  }) {
    return GoalState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, goals, errorMessage];
}
