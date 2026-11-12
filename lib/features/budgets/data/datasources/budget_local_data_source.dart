import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/budget.dart';

abstract class BudgetLocalDataSource {
  Stream<List<Budget>> watchBudgets();
  Future<List<Budget>> getBudgets();
  Future<void> insertBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String budgetId);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  final AppDatabase db;

  BudgetLocalDataSourceImpl(this.db);

  Budget _toDomain(BudgetsTableData row) {
    return Budget(
      id: row.id,
      name: row.name,
      amountInCents: row.amountInCents,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == row.period,
        orElse: () => BudgetPeriod.monthly,
      ),
      category: row.category,
      startDate: row.startDate,
      endDate: row.endDate,
      warningThresholdPercent: row.warningThresholdPercent,
      dangerThresholdPercent: row.dangerThresholdPercent,
      criticalThresholdPercent: row.criticalThresholdPercent,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  BudgetsTableCompanion _toCompanion(Budget budget) {
    return BudgetsTableCompanion(
      id: Value(budget.id),
      name: Value(budget.name),
      amountInCents: Value(budget.amountInCents),
      period: Value(budget.period.name),
      category: Value(budget.category),
      startDate: Value(budget.startDate),
      endDate: Value(budget.endDate),
      warningThresholdPercent: Value(budget.warningThresholdPercent),
      dangerThresholdPercent: Value(budget.dangerThresholdPercent),
      criticalThresholdPercent: Value(budget.criticalThresholdPercent),
      createdAt: Value(budget.createdAt),
      updatedAt: Value(budget.updatedAt),
    );
  }

  @override
  Stream<List<Budget>> watchBudgets() {
    return (db.select(db.budgetsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Budget>> getBudgets() async {
    final rows = await (db.select(db.budgetsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> insertBudget(Budget budget) async {
    await db.into(db.budgetsTable).insert(
          _toCompanion(budget),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await db.update(db.budgetsTable).replace(_toCompanion(budget));
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    await (db.delete(db.budgetsTable)..where((t) => t.id.equals(budgetId))).go();
  }
}
