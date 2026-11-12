import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Drift table representing authoritative financial transactions.
class TransactionsTable extends Table {
  TextColumn get id => text()();
  IntColumn get amountInCents => integer()();
  TextColumn get type => text()(); // 'income', 'expense', 'transfer', 'savingsDeposit', 'savingsWithdrawal'
  TextColumn get currency => text().withDefault(const Constant('ETB'))();
  TextColumn get category => text()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  TextColumn get account => text().withDefault(const Constant('Cash Wallet'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for income and expense categories.
class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get colorHex => text().withDefault(const Constant('#16865B'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for tracking payment accounts and wallets.
class AccountsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get accountType => text()(); // 'cash', 'bank', 'mobile_money', 'savings', 'custom'
  IntColumn get initialBalanceCents => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('ETB'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for user preferences and application settings.
class UserPreferencesTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Drift table for budget management with customizable alert thresholds.
class BudgetsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amountInCents => integer()();
  TextColumn get period => text()(); // 'daily', 'weekly', 'monthly', 'custom'
  TextColumn get category => text().nullable()(); // null indicates overall budget
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get warningThresholdPercent => integer().withDefault(const Constant(75))();
  IntColumn get dangerThresholdPercent => integer().withDefault(const Constant(90))();
  IntColumn get criticalThresholdPercent => integer().withDefault(const Constant(100))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for personal financial goals.
class GoalsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get targetAmountInCents => integer()();
  IntColumn get currentAmountInCents => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('ETB'))();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table tracking goal contributions history.
class GoalContributionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();
  IntColumn get amountInCents => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get sourceAccount => text().withDefault(const Constant('Cash Wallet'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for foreign exchange rates with effective dates.
class ExchangeRatesTable extends Table {
  TextColumn get id => text()();
  TextColumn get fromCurrency => text()();
  TextColumn get toCurrency => text()();
  RealColumn get rate => real()();
  DateTimeColumn get effectiveDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for tracking borrowed and lent money.
class DebtsTable extends Table {
  TextColumn get id => text()();
  TextColumn get personName => text()();
  TextColumn get debtType => text()(); // 'borrowed' or 'lent'
  IntColumn get initialAmountInCents => integer()();
  IntColumn get remainingAmountInCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('ETB'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for debt repayments history.
class DebtRepaymentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text()();
  IntColumn get amountInCents => integer()();
  DateTimeColumn get repaymentDate => dateTime()();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    TransactionsTable,
    CategoriesTable,
    AccountsTable,
    UserPreferencesTable,
    BudgetsTable,
    GoalsTable,
    GoalContributionsTable,
    ExchangeRatesTable,
    DebtsTable,
    DebtRepaymentsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'dailysave_db'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedInitialData();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(budgetsTable);
            await m.createTable(goalsTable);
            await m.createTable(goalContributionsTable);
            await m.createTable(exchangeRatesTable);
            await m.createTable(debtsTable);
            await m.createTable(debtRepaymentsTable);
            await _seedV2Data();
          }
        },
      );

  Future<void> _seedInitialData() async {
    // Pre-populate Standard Income Categories
    final incomeCategories = [
      'Salary',
      'Freelancing',
      'Business',
      'Tutoring',
      'Allowance',
      'Gifts',
      'Investments',
      'Rental income',
      'Other',
    ];

    for (final name in incomeCategories) {
      await into(categoriesTable).insert(
        CategoriesTableCompanion.insert(
          id: 'inc_${name.toLowerCase().replaceAll(' ', '_')}',
          name: name,
          type: 'income',
          colorHex: const Value('#16A34A'),
          isCustom: const Value(false),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    // Pre-populate Standard Expense Categories
    final expenseCategories = [
      'Food',
      'Transportation',
      'Education',
      'Housing',
      'Electricity',
      'Water',
      'Healthcare',
      'Communication',
      'Internet',
      'Entertainment',
      'Clothing',
      'Shopping',
      'Family support',
      'Business',
      'Personal care',
      'Other',
    ];

    for (final name in expenseCategories) {
      await into(categoriesTable).insert(
        CategoriesTableCompanion.insert(
          id: 'exp_${name.toLowerCase().replaceAll(' ', '_')}',
          name: name,
          type: 'expense',
          colorHex: const Value('#DC2626'),
          isCustom: const Value(false),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    // Pre-populate Common Ethiopian Accounts
    final defaultAccounts = [
      ('acc_cash', 'Cash Wallet', 'cash', 0),
      ('acc_telebirr', 'Telebirr', 'mobile_money', 0),
      ('acc_cbe', 'Commercial Bank of Ethiopia (CBE)', 'bank', 0),
      ('acc_savings', 'Emergency Savings Reserve', 'savings', 0),
    ];

    for (final acc in defaultAccounts) {
      await into(accountsTable).insert(
        AccountsTableCompanion.insert(
          id: acc.$1,
          name: acc.$2,
          accountType: acc.$3,
          initialBalanceCents: Value(acc.$4),
          currency: const Value('ETB'),
          isArchived: const Value(false),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    await _seedV2Data();
  }

  Future<void> _seedV2Data() async {
    final now = DateTime.now();

    // Seed default baseline exchange rate (USD to ETB)
    await into(exchangeRatesTable).insert(
      ExchangeRatesTableCompanion.insert(
        id: 'rate_usd_etb_initial',
        fromCurrency: 'USD',
        toCurrency: 'ETB',
        rate: 145.50,
        effectiveDate: now,
        createdAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );

    // Seed initial goal: Emergency Savings
    await into(goalsTable).insert(
      GoalsTableCompanion.insert(
        id: 'goal_emergency_fund',
        name: 'Build Emergency Savings',
        targetAmountInCents: 5000000, // 50,000 ETB
        currentAmountInCents: const Value(1000000), // 10,000 ETB
        currency: const Value('ETB'),
        deadline: now.add(const Duration(days: 180)),
        description: const Value('6 months of essential living expenses reserve'),
        createdAt: now,
        updatedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );

    // Seed initial monthly Food budget
    await into(budgetsTable).insert(
      BudgetsTableCompanion.insert(
        id: 'budget_monthly_food',
        name: 'Monthly Food & Groceries',
        amountInCents: 800000, // 8,000 ETB
        period: 'monthly',
        category: const Value('Food'),
        startDate: DateTime(now.year, now.month, 1),
        warningThresholdPercent: const Value(75),
        dangerThresholdPercent: const Value(90),
        criticalThresholdPercent: const Value(100),
        createdAt: now,
        updatedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}
