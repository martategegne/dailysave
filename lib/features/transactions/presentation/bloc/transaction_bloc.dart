import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;
  StreamSubscription<List<FinancialTransaction>>? _transactionsSubscription;

  TransactionBloc({required this.repository}) : super(const TransactionState()) {
    on<TransactionsSubscriptionRequested>(_onSubscriptionRequested);
    on<TransactionsUpdated>(_onTransactionsUpdated);
    on<TransactionsError>(_onTransactionsError);
    on<TransactionAdded>(_onTransactionAdded);
    on<TransactionUpdated>(_onTransactionUpdated);
    on<TransactionDeleted>(_onTransactionDeleted);
    on<TransactionFilterChanged>(_onFilterChanged);
    on<TransactionSearchQueryChanged>(_onSearchQueryChanged);

    // Automatically begin watching the local database
    add(const TransactionsSubscriptionRequested());
  }

  Future<void> _onSubscriptionRequested(
    TransactionsSubscriptionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(status: TransactionStatus.loading));

    await _transactionsSubscription?.cancel();
    _transactionsSubscription = repository
        .watchTransactions(filter: state.filter)
        .listen(
          (transactions) => add(TransactionsUpdated(transactions)),
          onError: (error) => add(TransactionsError(error.toString())),
        );
  }

  void _onTransactionsUpdated(
    TransactionsUpdated event,
    Emitter<TransactionState> emit,
  ) {
    emit(
      state.copyWith(
        status: TransactionStatus.success,
        transactions: event.transactions,
      ),
    );
  }

  void _onTransactionsError(
    TransactionsError event,
    Emitter<TransactionState> emit,
  ) {
    emit(
      state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: event.error,
      ),
    );
  }

  Future<void> _onTransactionAdded(
    TransactionAdded event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.addTransaction(event.transaction);
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: 'Failed to add transaction: $e',
      ));
    }
  }

  Future<void> _onTransactionUpdated(
    TransactionUpdated event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.updateTransaction(event.transaction);
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: 'Failed to update transaction: $e',
      ));
    }
  }

  Future<void> _onTransactionDeleted(
    TransactionDeleted event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.deleteTransaction(event.transactionId);
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: 'Failed to delete transaction: $e',
      ));
    }
  }

  void _onFilterChanged(
    TransactionFilterChanged event,
    Emitter<TransactionState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
    // Trigger updated database stream for new filter
    add(const TransactionsSubscriptionRequested());
  }

  void _onSearchQueryChanged(
    TransactionSearchQueryChanged event,
    Emitter<TransactionState> emit,
  ) {
    final updatedFilter = state.filter.copyWith(searchQuery: event.query);
    emit(state.copyWith(filter: updatedFilter));
    add(const TransactionsSubscriptionRequested());
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
