import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_data_source.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;

  BudgetRepositoryImpl(this.localDataSource);

  @override
  Stream<List<Budget>> watchBudgets() => localDataSource.watchBudgets();

  @override
  Future<List<Budget>> getBudgets() => localDataSource.getBudgets();

  @override
  Future<void> addBudget(Budget budget) => localDataSource.insertBudget(budget);

  @override
  Future<void> updateBudget(Budget budget) => localDataSource.updateBudget(budget);

  @override
  Future<void> deleteBudget(String budgetId) => localDataSource.deleteBudget(budgetId);
}
