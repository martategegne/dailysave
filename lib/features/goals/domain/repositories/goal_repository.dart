import '../entities/financial_goal.dart';

abstract class GoalRepository {
  Stream<List<FinancialGoal>> watchGoals();
  Future<List<FinancialGoal>> getGoals();
  Future<void> addGoal(FinancialGoal goal);
  Future<void> updateGoal(FinancialGoal goal);
  Future<void> deleteGoal(String goalId);

  Stream<List<GoalContribution>> watchContributions(String goalId);
  Future<void> addContribution(GoalContribution contribution);
}
