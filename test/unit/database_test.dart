import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dailysave/core/database/app_database.dart';
import 'package:dailysave/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:dailysave/features/transactions/data/models/financial_transaction_model.dart';
import 'package:dailysave/features/transactions/domain/entities/financial_transaction.dart';
import 'package:dailysave/features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionLocalDataSourceImpl dataSource;

  setUp(() {
    // In-memory SQLite database for rapid, isolated unit testing
    db = AppDatabase(NativeDatabase.memory());
    dataSource = TransactionLocalDataSourceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Local Database & Persistence Tests', () {
    final now = DateTime(2026, 11, 9, 12, 0);

    final testTransaction = FinancialTransactionModel(
      id: 'tx-uuid-1',
      amountInCents: 150000, // 1,500 ETB
      type: TransactionType.income,
      category: 'Freelancing',
      description: 'Flutter web consulting',
      date: now,
      paymentMethod: 'Telebirr',
      account: 'Telebirr',
      notes: 'Client milestone 1',
      createdAt: now,
      updatedAt: now,
    );

    test('Inserts and retrieves transaction from local database', () async {
      await dataSource.insertTransaction(testTransaction);

      final result = await dataSource.getTransactionById('tx-uuid-1');

      expect(result, isNotNull);
      expect(result!.id, 'tx-uuid-1');
      expect(result.amountInCents, 150000);
      expect(result.type, TransactionType.income);
      expect(result.category, 'Freelancing');
      expect(result.paymentMethod, 'Telebirr');
    });

    test('Updates an existing transaction correctly in local database', () async {
      await dataSource.insertTransaction(testTransaction);

      final updated = FinancialTransactionModel.fromEntity(
        testTransaction.copyWith(
          amountInCents: 200000, // Updated to 2,000 ETB
          description: 'Updated consulting milestone',
          updatedAt: DateTime.now(),
        ),
      );

      await dataSource.updateTransaction(updated);

      final retrieved = await dataSource.getTransactionById('tx-uuid-1');
      expect(retrieved!.amountInCents, 200000);
      expect(retrieved.description, 'Updated consulting milestone');
    });

    test('Deletes a transaction from local database', () async {
      await dataSource.insertTransaction(testTransaction);
      expect(await dataSource.getTransactionById('tx-uuid-1'), isNotNull);

      await dataSource.deleteTransaction('tx-uuid-1');

      final retrieved = await dataSource.getTransactionById('tx-uuid-1');
      expect(retrieved, isNull);
    });

    test('Prevents duplicate primary key insertion by replacing existing record', () async {
      await dataSource.insertTransaction(testTransaction);

      // Inserting identical ID with new amount
      final duplicate = FinancialTransactionModel.fromEntity(
        testTransaction.copyWith(amountInCents: 350000),
      );

      await dataSource.insertTransaction(duplicate);

      final all = await dataSource.getTransactions(null);
      expect(all.length, 1);
      expect(all.first.amountInCents, 350000);
    });

    test('Filters by search query matching description or category', () async {
      await dataSource.insertTransaction(testTransaction);

      final tx2 = FinancialTransactionModel(
        id: 'tx-uuid-2',
        amountInCents: 35000, // 350 ETB
        type: TransactionType.expense,
        category: 'Food',
        description: 'Supermarket grocery',
        date: now,
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.insertTransaction(tx2);

      final searchResults = await dataSource.getTransactions(
        const TransactionFilter(searchQuery: 'grocery'),
      );

      expect(searchResults.length, 1);
      expect(searchResults.first.id, 'tx-uuid-2');
    });

    test('Filters by transaction type (Income vs Expense)', () async {
      await dataSource.insertTransaction(testTransaction);

      final tx2 = FinancialTransactionModel(
        id: 'tx-uuid-2',
        amountInCents: 5000,
        type: TransactionType.expense,
        category: 'Transportation',
        description: 'Bus ticket',
        date: now,
        createdAt: now,
        updatedAt: now,
      );
      await dataSource.insertTransaction(tx2);

      final incomeOnly = await dataSource.getTransactions(
        const TransactionFilter(type: TransactionType.income),
      );
      expect(incomeOnly.length, 1);
      expect(incomeOnly.first.type, TransactionType.income);

      final expenseOnly = await dataSource.getTransactions(
        const TransactionFilter(type: TransactionType.expense),
      );
      expect(expenseOnly.length, 1);
      expect(expenseOnly.first.type, TransactionType.expense);
    });
  });
}
