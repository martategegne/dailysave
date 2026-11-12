import 'package:equatable/equatable.dart';

import '../../domain/entities/budget.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class BudgetSubscriptionRequested extends BudgetEvent {
  const BudgetSubscriptionRequested();
}

class BudgetAdded extends BudgetEvent {
  final Budget budget;
  const BudgetAdded(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetUpdated extends BudgetEvent {
  final Budget budget;
  const BudgetUpdated(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetDeleted extends BudgetEvent {
  final String budgetId;
  const BudgetDeleted(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}
