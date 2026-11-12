import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/financial_goal.dart';
import '../../domain/repositories/goal_repository.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class _GoalsUpdated extends GoalEvent {
  final List<FinancialGoal> goals;
  const _GoalsUpdated(this.goals);

  @override
  List<Object?> get props => [goals];
}

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GoalRepository goalRepository;
  StreamSubscription<List<FinancialGoal>>? _subscription;

  GoalBloc({required this.goalRepository}) : super(const GoalState()) {
    on<GoalSubscriptionRequested>(_onSubscriptionRequested);
    on<_GoalsUpdated>(_onGoalsUpdated);
    on<GoalAdded>(_onGoalAdded);
    on<GoalUpdated>(_onGoalUpdated);
    on<GoalDeleted>(_onGoalDeleted);
    on<GoalContributionSubmitted>(_onContributionSubmitted);

    add(const GoalSubscriptionRequested());
  }

  Future<void> _onSubscriptionRequested(
    GoalSubscriptionRequested event,
    Emitter<GoalState> emit,
  ) async {
    emit(state.copyWith(status: GoalStatus.loading));
    await _subscription?.cancel();
    _subscription = goalRepository.watchGoals().listen(
          (goals) => add(_GoalsUpdated(goals)),
          onError: (err) => emit(state.copyWith(
            status: GoalStatus.failure,
            errorMessage: err.toString(),
          )),
        );
  }

  void _onGoalsUpdated(
    _GoalsUpdated event,
    Emitter<GoalState> emit,
  ) {
    emit(state.copyWith(
      status: GoalStatus.success,
      goals: event.goals,
    ));
  }

  Future<void> _onGoalAdded(
    GoalAdded event,
    Emitter<GoalState> emit,
  ) async {
    await goalRepository.addGoal(event.goal);
  }

  Future<void> _onGoalUpdated(
    GoalUpdated event,
    Emitter<GoalState> emit,
  ) async {
    await goalRepository.updateGoal(event.goal);
  }

  Future<void> _onGoalDeleted(
    GoalDeleted event,
    Emitter<GoalState> emit,
  ) async {
    await goalRepository.deleteGoal(event.goalId);
  }

  Future<void> _onContributionSubmitted(
    GoalContributionSubmitted event,
    Emitter<GoalState> emit,
  ) async {
    await goalRepository.addContribution(event.contribution);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
