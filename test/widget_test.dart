import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dailysave/app/app.dart';
import 'package:dailysave/core/database/app_database.dart';
import 'package:dailysave/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:dailysave/features/transactions/data/repositories/transaction_repository_impl.dart';

void main() {
  group('DailySave Application Tests', () {
    testWidgets('DailySave application starts successfully',
        (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final dataSource = TransactionLocalDataSourceImpl(db);
      final repository = TransactionRepositoryImpl(dataSource);

      // Build the DailySave application with test database
      await tester.pumpWidget(DailySaveApp(
        database: db,
        transactionRepository: repository,
      ));
      await tester.pumpAndSettle();

      // Verify that the application widget is present.
      expect(find.byType(DailySaveApp), findsOneWidget);

      await db.close();
    });
  });
}
