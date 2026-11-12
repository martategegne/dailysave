import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dailysave/core/database/app_database.dart';
import 'package:dailysave/features/budgets/domain/entities/budget.dart';
import 'package:dailysave/features/goals/domain/entities/financial_goal.dart';
import 'package:dailysave/features/debts/domain/entities/debt.dart';
import 'package:dailysave/features/currencies/domain/entities/exchange_rate.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Milestone 3 — Database Schema & Domain Entity Tests', () {
    test('Initial migration seeds V2 baseline exchange rate, goal, and budget', () async {
      final rates = await db.select(db.exchangeRatesTable).get();
      expect(rates.isNotEmpty, isTrue);
      expect(rates.first.fromCurrency, 'USD');
      expect(rates.first.toCurrency, 'ETB');
      expect(rates.first.rate, 145.50);

      final goals = await db.select(db.goalsTable).get();
      expect(goals.isNotEmpty, isTrue);
      expect(goals.first.name, 'Build Emergency Savings');
      expect(goals.first.targetAmountInCents, 5000000);

      final budgets = await db.select(db.budgetsTable).get();
      expect(budgets.isNotEmpty, isTrue);
      expect(budgets.first.name, 'Monthly Food & Groceries');
      expect(budgets.first.category, 'Food');
    });

    test('Budget entity calculates correct alert statuses according to thresholds', () {
      final budget = Budget(
        id: 'b1',
        name: 'Weekly Transport',
        amountInCents: 100000, // 1,000 ETB
        period: BudgetPeriod.weekly,
        startDate: DateTime.now(),
        warningThresholdPercent: 75,
        dangerThresholdPercent: 90,
        criticalThresholdPercent: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Normal spending (< 75%)
      expect(budget.alertStatus(50000), BudgetAlertStatus.normal); // 500 ETB = 50%
      expect(budget.percentageUsed(50000), 50.0);
      expect(budget.remainingCents(50000), 50000);

      // Approaching warning threshold (>= 75% and < 90%)
      expect(budget.alertStatus(75000), BudgetAlertStatus.approaching75); // 750 ETB = 75%

      // Danger threshold (>= 90% and < 100%)
      expect(budget.alertStatus(92000), BudgetAlertStatus.warning90); // 920 ETB = 92%

      // Exceeded threshold (>= 100%)
      expect(budget.alertStatus(105000), BudgetAlertStatus.exceeded100); // 1,050 ETB = 105%
      expect(budget.remainingCents(105000), -5000); // Negative remaining
    });

    test('FinancialGoal entity computes progress, remaining amount, and overdue status', () {
      final goal = FinancialGoal(
        id: 'g1',
        name: 'Buy Laptop',
        targetAmountInCents: 8000000, // 80,000 ETB
        currentAmountInCents: 4000000, // 40,000 ETB
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressPercentage, 50.0);
      expect(goal.remainingAmountInCents, 4000000);
      expect(goal.isCompleted, isFalse);
      expect(goal.isOverdue(DateTime.now()), isFalse);

      final completedGoal = goal.copyWith(currentAmountInCents: 8000000);
      expect(completedGoal.progressPercentage, 100.0);
      expect(completedGoal.remainingAmountInCents, 0);
      expect(completedGoal.isCompleted, isTrue);
    });

    test('Debt entity tracks repayments and overdue calculations accurately', () {
      final debt = Debt(
        id: 'd1',
        personName: 'Abebe Kebede',
        debtType: DebtType.lent,
        initialAmountInCents: 500000, // 5,000 ETB
        remainingAmountInCents: 200000, // 2,000 ETB remaining
        dueDate: DateTime.now().subtract(const Duration(days: 2)), // Overdue
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(debt.repaidAmountInCents, 300000); // 3,000 ETB repaid
      expect(debt.repaymentPercentage, 60.0);
      expect(debt.isOverdue(DateTime.now()), isTrue);
    });

    test('ExchangeRate converts amounts between currencies accurately', () {
      final rate = ExchangeRate(
        id: 'r1',
        fromCurrency: 'USD',
        toCurrency: 'ETB',
        rate: 145.50,
        effectiveDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // 100 USD (10,000 cents) -> 14,550 ETB (1,455,000 cents)
      final convertedCents = rate.convertAmountInCents(10000);
      expect(convertedCents, 1455000);
    });
  });
}
