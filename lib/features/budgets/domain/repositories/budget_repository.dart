import '../entities/budget.dart';

abstract class BudgetRepository {
  Stream<List<Budget>> watchBudgets();
  Future<List<Budget>> getBudgets();
  Future<void> addBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String budgetId);
}
