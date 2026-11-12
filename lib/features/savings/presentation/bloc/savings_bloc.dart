import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../transactions/domain/entities/financial_transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import 'savings_event.dart';
import 'savings_state.dart';

class _SavingsTransactionsUpdated extends SavingsEvent {
  final List<FinancialTransaction> transactions;
  const _SavingsTransactionsUpdated(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  final TransactionRepository transactionRepository;
  StreamSubscription<List<FinancialTransaction>>? _subscription;

  SavingsBloc({required this.transactionRepository}) : super(const SavingsState()) {
    on<SavingsSubscriptionRequested>(_onSubscriptionRequested);
    on<_SavingsTransactionsUpdated>(_onTransactionsUpdated);
    on<SavingsDepositSubmitted>(_onDepositSubmitted);
    on<SavingsWithdrawalSubmitted>(_onWithdrawalSubmitted);

    add(const SavingsSubscriptionRequested());
  }

  Future<void> _onSubscriptionRequested(
    SavingsSubscriptionRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(state.copyWith(status: SavingsStatus.loading));
    await _subscription?.cancel();
    _subscription = transactionRepository.watchTransactions().listen(
          (transactions) => add(_SavingsTransactionsUpdated(transactions)),
          onError: (err) => emit(state.copyWith(
            status: SavingsStatus.failure,
            errorMessage: err.toString(),
          )),
        );
  }

  void _onTransactionsUpdated(
    _SavingsTransactionsUpdated event,
    Emitter<SavingsState> emit,
  ) {
    emit(state.copyWith(
      status: SavingsStatus.success,
      transactions: event.transactions,
    ));
  }

  Future<void> _onDepositSubmitted(
    SavingsDepositSubmitted event,
    Emitter<SavingsState> emit,
  ) async {
    final now = DateTime.now();
    final tx = FinancialTransaction(
      id: const Uuid().v4(),
      amountInCents: event.amountInCents,
      type: TransactionType.savingsDeposit,
      currency: 'ETB',
      category: 'Savings Deposit',
      description: event.description.isNotEmpty
          ? event.description
          : 'Deposit into ${event.savingsAccount}',
      date: event.date,
      paymentMethod: event.sourceAccount,
      account: event.savingsAccount,
      createdAt: now,
      updatedAt: now,
    );

    await transactionRepository.addTransaction(tx);
  }

  Future<void> _onWithdrawalSubmitted(
    SavingsWithdrawalSubmitted event,
    Emitter<SavingsState> emit,
  ) async {
    final now = DateTime.now();
    final tx = FinancialTransaction(
      id: const Uuid().v4(),
      amountInCents: event.amountInCents,
      type: TransactionType.savingsWithdrawal,
      currency: 'ETB',
      category: 'Savings Withdrawal',
      description: event.description.isNotEmpty
          ? event.description
          : 'Withdrawal from ${event.savingsAccount}',
      date: event.date,
      paymentMethod: event.savingsAccount,
      account: event.targetAccount,
      createdAt: now,
      updatedAt: now,
    );

    await transactionRepository.addTransaction(tx);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
