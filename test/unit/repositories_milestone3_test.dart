import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dailysave/core/database/app_database.dart';
import 'package:dailysave/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:dailysave/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:dailysave/features/budgets/domain/entities/budget.dart';
import 'package:dailysave/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:dailysave/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:dailysave/features/goals/domain/entities/financial_goal.dart';
import 'package:dailysave/features/debts/data/datasources/debt_local_data_source.dart';
import 'package:dailysave/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:dailysave/features/debts/domain/entities/debt.dart';
import 'package:dailysave/features/currencies/data/datasources/currency_local_data_source.dart';
import 'package:dailysave/features/currencies/data/repositories/currency_repository_impl.dart';

void main() {
  late AppDatabase db;
  late BudgetRepositoryImpl budgetRepo;
  late GoalRepositoryImpl goalRepo;
  late DebtRepositoryImpl debtRepo;
  late CurrencyRepositoryImpl currencyRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    budgetRepo = BudgetRepositoryImpl(BudgetLocalDataSourceImpl(db));
    goalRepo = GoalRepositoryImpl(GoalLocalDataSourceImpl(db));
    debtRepo = DebtRepositoryImpl(DebtLocalDataSourceImpl(db));
    currencyRepo = CurrencyRepositoryImpl(CurrencyLocalDataSourceImpl(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('Milestone 3 Repository Tests', () {
    test('BudgetRepository adds, updates, and deletes budget', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: 'test_b1',
        name: 'Entertainment Budget',
        amountInCents: 200000,
        period: BudgetPeriod.monthly,
        category: 'Entertainment',
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await budgetRepo.addBudget(budget);
      var budgets = await budgetRepo.getBudgets();
      expect(budgets.any((b) => b.id == 'test_b1'), isTrue);

      // Update
      final updated = budget.copyWith(amountInCents: 250000);
      await budgetRepo.updateBudget(updated);
      budgets = await budgetRepo.getBudgets();
      expect(budgets.firstWhere((b) => b.id == 'test_b1').amountInCents, 250000);

      // Delete
      await budgetRepo.deleteBudget('test_b1');
      budgets = await budgetRepo.getBudgets();
      expect(budgets.any((b) => b.id == 'test_b1'), isFalse);
    });

    test('GoalRepository adds contribution and atomically updates current amount', () async {
      final now = DateTime.now();
      final goal = FinancialGoal(
        id: 'test_g1',
        name: 'Start Business',
        targetAmountInCents: 10000000, // 100,000 ETB
        currentAmountInCents: 1000000,  // 10,000 ETB
        deadline: now.add(const Duration(days: 365)),
        createdAt: now,
        updatedAt: now,
      );

      await goalRepo.addGoal(goal);

      // Add a contribution of 15,000 ETB (1,500,000 cents)
      final contribution = GoalContribution(
        id: 'contrib_1',
        goalId: 'test_g1',
        amountInCents: 1500000,
        date: now,
        notes: 'Bonus from freelancing',
      );
      await goalRepo.addContribution(contribution);

      final goals = await goalRepo.getGoals();
      final savedGoal = goals.firstWhere((g) => g.id == 'test_g1');
      expect(savedGoal.currentAmountInCents, 2500000); // 10,000 + 15,000 = 25,000 ETB
      expect(savedGoal.progressPercentage, 25.0);
    });

    test('DebtRepository records repayments and settles debt when balance hits zero', () async {
      final now = DateTime.now();
      final debt = Debt(
        id: 'test_d1',
        personName: 'Almaz',
        debtType: DebtType.borrowed,
        initialAmountInCents: 400000, // 4,000 ETB
        remainingAmountInCents: 400000,
        createdAt: now,
        updatedAt: now,
      );

      await debtRepo.addDebt(debt);

      // Partial repayment: 2,500 ETB
      await debtRepo.recordRepayment(DebtRepayment(
        id: 'rep_1',
        debtId: 'test_d1',
        amountInCents: 250000,
        repaymentDate: now,
        createdAt: now,
      ));

      var debts = await debtRepo.getDebts();
      var savedDebt = debts.firstWhere((d) => d.id == 'test_d1');
      expect(savedDebt.remainingAmountInCents, 150000); // 1,500 ETB remaining
      expect(savedDebt.isSettled, isFalse);

      // Final repayment: 1,500 ETB
      await debtRepo.recordRepayment(DebtRepayment(
        id: 'rep_2',
        debtId: 'test_d1',
        amountInCents: 150000,
        repaymentDate: now,
        createdAt: now,
      ));

      debts = await debtRepo.getDebts();
      savedDebt = debts.firstWhere((d) => d.id == 'test_d1');
      expect(savedDebt.remainingAmountInCents, 0);
      expect(savedDebt.isSettled, isTrue);
    });

    test('CurrencyRepository fetches USD to ETB exchange rate', () async {
      final rate = await currencyRepo.getRate('USD', 'ETB');
      expect(rate, isNotNull);
      expect(rate!.rate, 145.50);

      // Same currency returns 1.0 rate
      final sameRate = await currencyRepo.getRate('ETB', 'ETB');
      expect(sameRate!.rate, 1.0);
    });
  });
}
