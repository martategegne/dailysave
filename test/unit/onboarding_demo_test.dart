import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailysave/core/database/app_database.dart';
import 'package:dailysave/features/onboarding/domain/entities/demo_data.dart';
import 'package:dailysave/features/onboarding/presentation/demo_data_generator.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Onboarding & Fictional Demo Datasets Suite', () {
    test('Fictional datasets contain valid profiles without real personal records', () {
      expect(DemoDatasets.studentProfile.transactions, isNotEmpty);
      expect(DemoDatasets.familyProfile.transactions, isNotEmpty);
      expect(DemoDatasets.merchantProfile.transactions, isNotEmpty);

      for (final tx in DemoDatasets.studentProfile.transactions) {
        expect(tx.amountCents, greaterThan(0));
        expect(tx.account, isNotEmpty);
      }
    });

    test('DemoDataGenerator seeds student profile into local SQLite database cleanly', () async {
      await DemoDataGenerator.seedFictionalProfile(db, DemoDatasets.studentProfile);

      // Verify accounts were seeded
      final accounts = await db.select(db.accountsTable).get();
      expect(accounts.length, greaterThanOrEqualTo(2));
      expect(accounts.any((a) => a.id == 'acc_demo_cash'), isTrue);
      expect(accounts.any((a) => a.id == 'acc_demo_telebirr'), isTrue);

      // Verify transactions were seeded
      final transactions = await db.select(db.transactionsTable).get();
      expect(transactions.length, DemoDatasets.studentProfile.transactions.length);
      expect(transactions.every((t) => t.notes?.contains('Fictional') ?? false), isTrue);

      // Verify onboarding preference was saved
      final prefs = await db.select(db.userPreferencesTable).get();
      final onboardingFlag = prefs.firstWhere((p) => p.key == 'onboarding_completed');
      expect(onboardingFlag.value, 'true');
    });
  });
}
