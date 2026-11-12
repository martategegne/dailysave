import 'package:equatable/equatable.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Request to start listening to local database transactions.
class TransactionsSubscriptionRequested extends TransactionEvent {
  const TransactionsSubscriptionRequested();
}

/// Dispatched when user submits a new financial transaction.
class TransactionAdded extends TransactionEvent {
  final FinancialTransaction transaction;

  const TransactionAdded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Dispatched when user updates an existing financial transaction.
class TransactionUpdated extends TransactionEvent {
  final FinancialTransaction transaction;

  const TransactionUpdated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Dispatched when user removes a transaction by ID.
class TransactionDeleted extends TransactionEvent {
  final String transactionId;

  const TransactionDeleted(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

/// Dispatched when user modifies filter criteria (date range, type, category, account).
class TransactionFilterChanged extends TransactionEvent {
  final TransactionFilter filter;

  const TransactionFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Dispatched when user types into the search field.
class TransactionSearchQueryChanged extends TransactionEvent {
  final String query;

  const TransactionSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Internal event dispatched when the database stream emits updated transactions.
class TransactionsUpdated extends TransactionEvent {
  final List<FinancialTransaction> transactions;

  const TransactionsUpdated(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// Internal event dispatched when the database stream encounters an error.
class TransactionsError extends TransactionEvent {
  final String error;

  const TransactionsError(this.error);

  @override
  List<Object?> get props => [error];
}
