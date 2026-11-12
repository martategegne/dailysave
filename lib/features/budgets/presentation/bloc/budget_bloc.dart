import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transactions/domain/entities/financial_transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class _BudgetsLoaded extends BudgetEvent {
  final List<Budget> budgets;
  const _BudgetsLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class _BudgetTransactionsLoaded extends BudgetEvent {
  final List<FinancialTransaction> transactions;
  const _BudgetTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository budgetRepository;
  final TransactionRepository transactionRepository;

  StreamSubscription<List<Budget>>? _budgetsSubscription;
  StreamSubscription<List<FinancialTransaction>>? _txSubscription;

  BudgetBloc({
    required this.budgetRepository,
    required this.transactionRepository,
  }) : super(const BudgetState()) {
    on<BudgetSubscriptionRequested>(_onSubscriptionRequested);
    on<_BudgetsLoaded>(_onBudgetsLoaded);
    on<_BudgetTransactionsLoaded>(_onTransactionsLoaded);
    on<BudgetAdded>(_onBudgetAdded);
    on<BudgetUpdated>(_onBudgetUpdated);
    on<BudgetDeleted>(_onBudgetDeleted);

    add(const BudgetSubscriptionRequested());
  }

  Future<void> _onSubscriptionRequested(
    BudgetSubscriptionRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(state.copyWith(status: BudgetStatus.loading));

    await _budgetsSubscription?.cancel();
    _budgetsSubscription = budgetRepository.watchBudgets().listen(
          (budgets) => add(_BudgetsLoaded(budgets)),
          onError: (err) => emit(state.copyWith(
            status: BudgetStatus.failure,
            errorMessage: err.toString(),
          )),
        );

    await _txSubscription?.cancel();
    _txSubscription = transactionRepository.watchTransactions().listen(
          (transactions) => add(_BudgetTransactionsLoaded(transactions)),
        );
  }

  void _onBudgetsLoaded(
    _BudgetsLoaded event,
    Emitter<BudgetState> emit,
  ) {
    emit(state.copyWith(
      status: BudgetStatus.success,
      budgets: event.budgets,
    ));
  }

  void _onTransactionsLoaded(
    _BudgetTransactionsLoaded event,
    Emitter<BudgetState> emit,
  ) {
    emit(state.copyWith(
      transactions: event.transactions,
    ));
  }

  Future<void> _onBudgetAdded(
    BudgetAdded event,
    Emitter<BudgetState> emit,
  ) async {
    await budgetRepository.addBudget(event.budget);
  }

  Future<void> _onBudgetUpdated(
    BudgetUpdated event,
    Emitter<BudgetState> emit,
  ) async {
    await budgetRepository.updateBudget(event.budget);
  }

  Future<void> _onBudgetDeleted(
    BudgetDeleted event,
    Emitter<BudgetState> emit,
  ) async {
    await budgetRepository.deleteBudget(event.budgetId);
  }

  @override
  Future<void> close() async {
    await _budgetsSubscription?.cancel();
    await _txSubscription?.cancel();
    return super.close();
  }
}
