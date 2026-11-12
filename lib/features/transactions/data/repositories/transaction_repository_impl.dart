import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_data_source.dart';
import '../models/financial_transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl(this.localDataSource);

  @override
  Future<List<FinancialTransaction>> getTransactions({TransactionFilter? filter}) async {
    return localDataSource.getTransactions(filter);
  }

  @override
  Stream<List<FinancialTransaction>> watchTransactions({TransactionFilter? filter}) {
    return localDataSource.watchTransactions(filter);
  }

  @override
  Future<FinancialTransaction?> getTransactionById(String id) async {
    return localDataSource.getTransactionById(id);
  }

  @override
  Future<void> addTransaction(FinancialTransaction transaction) async {
    final model = FinancialTransactionModel.fromEntity(transaction);
    await localDataSource.insertTransaction(model);
  }

  @override
  Future<void> updateTransaction(FinancialTransaction transaction) async {
    final model = FinancialTransactionModel.fromEntity(transaction);
    await localDataSource.updateTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await localDataSource.deleteTransaction(id);
  }
}
