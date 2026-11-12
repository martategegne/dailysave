import '../../domain/entities/financial_goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_local_data_source.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalLocalDataSource localDataSource;

  GoalRepositoryImpl(this.localDataSource);

  @override
  Stream<List<FinancialGoal>> watchGoals() => localDataSource.watchGoals();

  @override
  Future<List<FinancialGoal>> getGoals() => localDataSource.getGoals();

  @override
  Future<void> addGoal(FinancialGoal goal) => localDataSource.insertGoal(goal);

  @override
  Future<void> updateGoal(FinancialGoal goal) => localDataSource.updateGoal(goal);

  @override
  Future<void> deleteGoal(String goalId) => localDataSource.deleteGoal(goalId);

  @override
  Stream<List<GoalContribution>> watchContributions(String goalId) =>
      localDataSource.watchContributions(goalId);

  @override
  Future<void> addContribution(GoalContribution contribution) =>
      localDataSource.insertContribution(contribution);
}
