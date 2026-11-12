import 'package:equatable/equatable.dart';

import '../../domain/entities/financial_goal.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object?> get props => [];
}

class GoalSubscriptionRequested extends GoalEvent {
  const GoalSubscriptionRequested();
}

class GoalAdded extends GoalEvent {
  final FinancialGoal goal;
  const GoalAdded(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalUpdated extends GoalEvent {
  final FinancialGoal goal;
  const GoalUpdated(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalDeleted extends GoalEvent {
  final String goalId;
  const GoalDeleted(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class GoalContributionSubmitted extends GoalEvent {
  final GoalContribution contribution;
  const GoalContributionSubmitted(this.contribution);

  @override
  List<Object?> get props => [contribution];
}
