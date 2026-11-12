import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/financial_transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<FinancialTransactionModel>> getTransactions(TransactionFilter? filter);
  Stream<List<FinancialTransactionModel>> watchTransactions(TransactionFilter? filter);
  Future<FinancialTransactionModel?> getTransactionById(String id);
  Future<void> insertTransaction(FinancialTransactionModel model);
  Future<void> updateTransaction(FinancialTransactionModel model);
  Future<void> deleteTransaction(String id);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final AppDatabase database;

  TransactionLocalDataSourceImpl(this.database);

  SimpleSelectStatement<$TransactionsTableTable, TransactionsTableData> _buildQuery(
      TransactionFilter? filter) {
    var query = database.select(database.transactionsTable);

    if (filter != null) {
      query = query
        ..where((tbl) {
          final predicates = <Expression<bool>>[];

          if (filter.startDate != null) {
            predicates.add(tbl.date.isBiggerOrEqualValue(filter.startDate!));
          }
          if (filter.endDate != null) {
            predicates.add(tbl.date.isSmallerOrEqualValue(filter.endDate!));
          }
          if (filter.type != null) {
            predicates.add(tbl.type.equals(filter.type!.name));
          }
          if (filter.category != null && filter.category!.isNotEmpty) {
            predicates.add(tbl.category.equals(filter.category!));
          }
          if (filter.account != null && filter.account!.isNotEmpty) {
            predicates.add(tbl.account.equals(filter.account!));
          }
          if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
            final term = '%${filter.searchQuery!.trim().toLowerCase()}%';
            predicates.add(
              tbl.description.lower().like(term) |
                  tbl.category.lower().like(term) |
                  tbl.notes.lower().like(term) |
                  tbl.account.lower().like(term),
            );
          }

          return predicates.isEmpty
              ? const Constant(true)
              : predicates.reduce((a, b) => a & b);
        });
    }

    return query
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ]);
  }

  @override
  Future<List<FinancialTransactionModel>> getTransactions(TransactionFilter? filter) async {
    final rows = await _buildQuery(filter).get();
    return rows.map(FinancialTransactionModel.fromDrift).toList();
  }

  @override
  Stream<List<FinancialTransactionModel>> watchTransactions(TransactionFilter? filter) {
    return _buildQuery(filter)
        .watch()
        .map((rows) => rows.map(FinancialTransactionModel.fromDrift).toList());
  }

  @override
  Future<FinancialTransactionModel?> getTransactionById(String id) async {
    final query = database.select(database.transactionsTable)
      ..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : FinancialTransactionModel.fromDrift(row);
  }

  @override
  Future<void> insertTransaction(FinancialTransactionModel model) async {
    await database.into(database.transactionsTable).insert(
          model.toCompanion(),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> updateTransaction(FinancialTransactionModel model) async {
    await database.update(database.transactionsTable).replace(model.toCompanion());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (database.delete(database.transactionsTable)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
