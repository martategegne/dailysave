import 'package:flutter_test/flutter_test.dart';
import 'package:dailysave/features/transactions/domain/entities/financial_transaction.dart';
import 'package:dailysave/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:dailysave/features/transactions/presentation/bloc/transaction_state.dart';

void main() {
  group('DailySave Financial Calculations & State Tests', () {
    final now = DateTime(2026, 11, 9, 14, 30);
    final yesterday = DateTime(2026, 11, 8, 10, 0);

    final transactions = [
      FinancialTransaction(
        id: '1',
        amountInCents: 100000, // 1,000 ETB
        type: TransactionType.income,
        category: 'Salary',
        description: 'Daily consultant payment',
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      FinancialTransaction(
        id: '2',
        amountInCents: 15000, // 150 ETB
        type: TransactionType.expense,
        category: 'Food',
        description: 'Lunch',
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      FinancialTransaction(
        id: '3',
        amountInCents: 10000, // 100 ETB
        type: TransactionType.expense,
        category: 'Transportation',
        description: 'Bus fare',
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      FinancialTransaction(
        id: '4',
        amountInCents: 20000, // 200 ETB
        type: TransactionType.expense,
        category: 'Internet',
        description: 'Mobile data voucher',
        date: yesterday,
        createdAt: yesterday,
        updatedAt: yesterday,
      ),
    ];

    final state = TransactionState(transactions: transactions);

    test('Calculates total income correctly across all entries', () {
      expect(state.totalIncome, 100000);
    });

    test('Calculates total expenses correctly across all entries', () {
      expect(state.totalExpenses, 45000);
    });

    test('Calculates accumulated savings correctly (Income - Expenses)', () {
      expect(state.savings, 55000);
    });

    test('Calculates savings percentage correctly', () {
      expect(state.savingsPercentage, closeTo(55.0, 0.001));
    });

    test('Calculates daily income and expenses adhering to date boundaries', () {
      expect(state.dailyIncome(now), 100000);
      expect(state.dailyExpenses(now), 25000);
      expect(state.dailySavings(now), 75000); // 1,000 ETB - 250 ETB = 750 ETB

      // Yesterday
      expect(state.dailyIncome(yesterday), 0);
      expect(state.dailyExpenses(yesterday), 20000);
      expect(state.dailySavings(yesterday), -20000); // Negative savings
    });

    test('Calculates valid negative savings when daily expenses exceed income', () {
      final negativeDay = DateTime(2026, 11, 10);
      final deficitState = TransactionState(
        transactions: [
          FinancialTransaction(
            id: 'd1',
            amountInCents: 50000, // 500 ETB
            type: TransactionType.income,
            category: 'Tutoring',
            description: 'Lesson fee',
            date: negativeDay,
            createdAt: negativeDay,
            updatedAt: negativeDay,
          ),
          FinancialTransaction(
            id: 'd2',
            amountInCents: 70000, // 700 ETB
            type: TransactionType.expense,
            category: 'Healthcare',
            description: 'Pharmacy medicine',
            date: negativeDay,
            createdAt: negativeDay,
            updatedAt: negativeDay,
          ),
        ],
      );

      expect(deficitState.dailyIncome(negativeDay), 50000);
      expect(deficitState.dailyExpenses(negativeDay), 70000);
      expect(deficitState.dailySavings(negativeDay), -20000); // -200 ETB
      expect(deficitState.savings, -20000);
      expect(deficitState.savingsPercentage, 0.0);
    });

    test('Handles empty days correctly with 0 savings and 0 totals', () {
      final emptyDay = DateTime(2026, 12, 1);
      expect(state.dailyIncome(emptyDay), 0);
      expect(state.dailyExpenses(emptyDay), 0);
      expect(state.dailySavings(emptyDay), 0);
    });

    test('Filters transactions correctly by category, type, and search query', () {
      final searchFiltered = state.copyWith(
        filter: const TransactionFilter(searchQuery: 'lunch'),
      );
      expect(searchFiltered.filteredTransactions.length, 1);
      expect(searchFiltered.filteredTransactions.first.description, 'Lunch');

      final typeFiltered = state.copyWith(
        filter: const TransactionFilter(type: TransactionType.income),
      );
      expect(typeFiltered.filteredTransactions.length, 1);
      expect(typeFiltered.filteredTransactions.first.category, 'Salary');
    });

    test('Excludes personal transfers from operating income and expenses', () {
      final transferState = TransactionState(
        transactions: [
          FinancialTransaction(
            id: 't1',
            amountInCents: 50000, // 500 ETB transfer
            type: TransactionType.transfer,
            category: 'Account Transfer',
            description: 'Moved money from Bank to Telebirr',
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      expect(transferState.totalIncome, 0);
      expect(transferState.totalExpenses, 0);
      expect(transferState.savings, 0);
    });
  });
}
