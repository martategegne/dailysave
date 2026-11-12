import '../entities/financial_transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<List<FinancialTransaction>> call({TransactionFilter? filter}) {
    return repository.getTransactions(filter: filter);
  }

  Stream<List<FinancialTransaction>> watch({TransactionFilter? filter}) {
    return repository.watchTransactions(filter: filter);
  }
}

class AddTransactionUseCase {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  Future<void> call(FinancialTransaction transaction) {
    return repository.addTransaction(transaction);
  }
}

class EditTransactionUseCase {
  final TransactionRepository repository;

  EditTransactionUseCase(this.repository);

  Future<void> call(FinancialTransaction transaction) {
    return repository.updateTransaction(transaction);
  }
}

class DeleteTransactionUseCase {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteTransaction(id);
  }
}
