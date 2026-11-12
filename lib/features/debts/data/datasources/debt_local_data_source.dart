import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/debt.dart';

abstract class DebtLocalDataSource {
  Stream<List<Debt>> watchDebts();
  Future<List<Debt>> getDebts();
  Future<void> insertDebt(Debt debt);
  Future<void> updateDebt(Debt debt);
  Future<void> deleteDebt(String debtId);

  Stream<List<DebtRepayment>> watchRepayments(String debtId);
  Future<void> insertRepayment(DebtRepayment repayment);
}

class DebtLocalDataSourceImpl implements DebtLocalDataSource {
  final AppDatabase db;

  DebtLocalDataSourceImpl(this.db);

  Debt _toDomainDebt(DebtsTableData row) {
    return Debt(
      id: row.id,
      personName: row.personName,
      debtType: row.debtType == 'lent' ? DebtType.lent : DebtType.borrowed,
      initialAmountInCents: row.initialAmountInCents,
      remainingAmountInCents: row.remainingAmountInCents,
      currency: row.currency,
      dueDate: row.dueDate,
      description: row.description,
      isSettled: row.isSettled,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  DebtsTableCompanion _toDebtCompanion(Debt debt) {
    return DebtsTableCompanion(
      id: Value(debt.id),
      personName: Value(debt.personName),
      debtType: Value(debt.debtType.name),
      initialAmountInCents: Value(debt.initialAmountInCents),
      remainingAmountInCents: Value(debt.remainingAmountInCents),
      currency: Value(debt.currency),
      dueDate: Value(debt.dueDate),
      description: Value(debt.description),
      isSettled: Value(debt.isSettled),
      createdAt: Value(debt.createdAt),
      updatedAt: Value(debt.updatedAt),
    );
  }

  DebtRepayment _toDomainRepayment(DebtRepaymentsTableData row) {
    return DebtRepayment(
      id: row.id,
      debtId: row.debtId,
      amountInCents: row.amountInCents,
      repaymentDate: row.repaymentDate,
      paymentMethod: row.paymentMethod,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }

  DebtRepaymentsTableCompanion _toRepaymentCompanion(DebtRepayment repayment) {
    return DebtRepaymentsTableCompanion(
      id: Value(repayment.id),
      debtId: Value(repayment.debtId),
      amountInCents: Value(repayment.amountInCents),
      repaymentDate: Value(repayment.repaymentDate),
      paymentMethod: Value(repayment.paymentMethod),
      notes: Value(repayment.notes),
      createdAt: Value(repayment.createdAt),
    );
  }

  @override
  Stream<List<Debt>> watchDebts() {
    return (db.select(db.debtsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isSettled, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_toDomainDebt).toList());
  }

  @override
  Future<List<Debt>> getDebts() async {
    final rows = await (db.select(db.debtsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isSettled, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_toDomainDebt).toList();
  }

  @override
  Future<void> insertDebt(Debt debt) async {
    await db.into(db.debtsTable).insert(
          _toDebtCompanion(debt),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    await db.update(db.debtsTable).replace(_toDebtCompanion(debt));
  }

  @override
  Future<void> deleteDebt(String debtId) async {
    await (db.delete(db.debtRepaymentsTable)..where((t) => t.debtId.equals(debtId))).go();
    await (db.delete(db.debtsTable)..where((t) => t.id.equals(debtId))).go();
  }

  @override
  Stream<List<DebtRepayment>> watchRepayments(String debtId) {
    return (db.select(db.debtRepaymentsTable)
          ..where((t) => t.debtId.equals(debtId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.repaymentDate, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_toDomainRepayment).toList());
  }

  @override
  Future<void> insertRepayment(DebtRepayment repayment) async {
    await db.transaction(() async {
      await db.into(db.debtRepaymentsTable).insert(
            _toRepaymentCompanion(repayment),
            mode: InsertMode.insertOrReplace,
          );

      // Decrement remainingAmountInCents on the debt atomically
      final debtRow = await (db.select(db.debtsTable)
            ..where((t) => t.id.equals(repayment.debtId)))
          .getSingleOrNull();

      if (debtRow != null) {
        final newRemaining = debtRow.remainingAmountInCents - repayment.amountInCents;
        final settled = newRemaining <= 0;

        await (db.update(db.debtsTable)..where((t) => t.id.equals(repayment.debtId)))
            .write(
          DebtsTableCompanion(
            remainingAmountInCents: Value(newRemaining > 0 ? newRemaining : 0),
            isSettled: Value(settled),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}
