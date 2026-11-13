import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/demo_data.dart';

class DemoDataGenerator {
  DemoDataGenerator._();

  /// Safely loads fictional profile data into the local Drift SQLite database.
  /// Enables complete onboarding exploration without requiring real personal financial data.
  static Future<void> seedFictionalProfile(AppDatabase db, DemoDataProfile profile) async {
    final now = DateTime.now();

    // 1. Seed Accounts
    await db.into(db.accountsTable).insertOnConflictUpdate(
      AccountsTableCompanion(
        id: const Value('acc_demo_cash'),
        name: const Value('Cash Wallet'),
        accountType: const Value('cash'),
        initialBalanceCents: Value(profile.initialBalanceCents),
        currency: const Value('ETB'),
      ),
    );

    await db.into(db.accountsTable).insertOnConflictUpdate(
      AccountsTableCompanion(
        id: const Value('acc_demo_telebirr'),
        name: const Value('Telebirr'),
        accountType: const Value('mobile_money'),
        initialBalanceCents: const Value(0),
        currency: const Value('ETB'),
      ),
    );

    // 2. Seed Transactions
    int counter = 0;
    for (final tx in profile.transactions) {
      counter++;
      final txDate = now.subtract(Duration(days: counter));
      await db.into(db.transactionsTable).insertOnConflictUpdate(
        TransactionsTableCompanion(
          id: Value('demo_tx_$counter'),
          amountInCents: Value(tx.amountCents),
          type: Value(tx.type),
          currency: const Value('ETB'),
          category: Value(tx.category),
          description: Value(tx.description),
          date: Value(txDate),
          paymentMethod: Value(tx.account),
          account: Value(tx.account),
          notes: const Value('Fictional demo record for onboarding validation'),
          createdAt: Value(txDate),
          updatedAt: Value(txDate),
        ),
      );
    }

    // 3. Set Onboarding Completed Flag
    await db.into(db.userPreferencesTable).insertOnConflictUpdate(
      const UserPreferencesTableCompanion(
        key: Value('onboarding_completed'),
        value: Value('true'),
      ),
    );
  }
}
