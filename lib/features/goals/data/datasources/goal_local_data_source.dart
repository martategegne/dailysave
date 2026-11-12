import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/financial_goal.dart';

abstract class GoalLocalDataSource {
  Stream<List<FinancialGoal>> watchGoals();
  Future<List<FinancialGoal>> getGoals();
  Future<void> insertGoal(FinancialGoal goal);
  Future<void> updateGoal(FinancialGoal goal);
  Future<void> deleteGoal(String goalId);

  Stream<List<GoalContribution>> watchContributions(String goalId);
  Future<void> insertContribution(GoalContribution contribution);
}

class GoalLocalDataSourceImpl implements GoalLocalDataSource {
  final AppDatabase db;

  GoalLocalDataSourceImpl(this.db);

  FinancialGoal _toDomainGoal(GoalsTableData row) {
    return FinancialGoal(
      id: row.id,
      name: row.name,
      targetAmountInCents: row.targetAmountInCents,
      currentAmountInCents: row.currentAmountInCents,
      currency: row.currency,
      deadline: row.deadline,
      description: row.description,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  GoalsTableCompanion _toGoalCompanion(FinancialGoal goal) {
    return GoalsTableCompanion(
      id: Value(goal.id),
      name: Value(goal.name),
      targetAmountInCents: Value(goal.targetAmountInCents),
      currentAmountInCents: Value(goal.currentAmountInCents),
      currency: Value(goal.currency),
      deadline: Value(goal.deadline),
      description: Value(goal.description),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
    );
  }

  GoalContribution _toDomainContribution(GoalContributionsTableData row) {
    return GoalContribution(
      id: row.id,
      goalId: row.goalId,
      amountInCents: row.amountInCents,
      date: row.date,
      notes: row.notes,
      sourceAccount: row.sourceAccount,
    );
  }

  GoalContributionsTableCompanion _toContributionCompanion(
      GoalContribution contribution) {
    return GoalContributionsTableCompanion(
      id: Value(contribution.id),
      goalId: Value(contribution.goalId),
      amountInCents: Value(contribution.amountInCents),
      date: Value(contribution.date),
      notes: Value(contribution.notes),
      sourceAccount: Value(contribution.sourceAccount),
    );
  }

  @override
  Stream<List<FinancialGoal>> watchGoals() {
    return (db.select(db.goalsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.deadline, mode: OrderingMode.asc)
          ]))
        .watch()
        .map((rows) => rows.map(_toDomainGoal).toList());
  }

  @override
  Future<List<FinancialGoal>> getGoals() async {
    final rows = await (db.select(db.goalsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.deadline, mode: OrderingMode.asc)
          ]))
        .get();
    return rows.map(_toDomainGoal).toList();
  }

  @override
  Future<void> insertGoal(FinancialGoal goal) async {
    await db.into(db.goalsTable).insert(
          _toGoalCompanion(goal),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> updateGoal(FinancialGoal goal) async {
    await db.update(db.goalsTable).replace(_toGoalCompanion(goal));
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await (db.delete(db.goalContributionsTable)
          ..where((t) => t.goalId.equals(goalId)))
        .go();
    await (db.delete(db.goalsTable)..where((t) => t.id.equals(goalId))).go();
  }

  @override
  Stream<List<GoalContribution>> watchContributions(String goalId) {
    return (db.select(db.goalContributionsTable)
          ..where((t) => t.goalId.equals(goalId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .watch()
        .map((rows) => rows.map(_toDomainContribution).toList());
  }

  @override
  Future<void> insertContribution(GoalContribution contribution) async {
    await db.transaction(() async {
      await db.into(db.goalContributionsTable).insert(
            _toContributionCompanion(contribution),
            mode: InsertMode.insertOrReplace,
          );

      // Increment currentAmountInCents on the goal atomically
      final goalRow = await (db.select(db.goalsTable)
            ..where((t) => t.id.equals(contribution.goalId)))
          .getSingleOrNull();

      if (goalRow != null) {
        final updatedAmount =
            goalRow.currentAmountInCents + contribution.amountInCents;
        await (db.update(db.goalsTable)
              ..where((t) => t.id.equals(contribution.goalId)))
            .write(
          GoalsTableCompanion(
            currentAmountInCents: Value(updatedAmount),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}
