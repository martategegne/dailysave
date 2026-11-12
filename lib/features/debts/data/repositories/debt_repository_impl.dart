import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_local_data_source.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtLocalDataSource localDataSource;

  DebtRepositoryImpl(this.localDataSource);

  @override
  Stream<List<Debt>> watchDebts() => localDataSource.watchDebts();

  @override
  Future<List<Debt>> getDebts() => localDataSource.getDebts();

  @override
  Future<void> addDebt(Debt debt) => localDataSource.insertDebt(debt);

  @override
  Future<void> updateDebt(Debt debt) => localDataSource.updateDebt(debt);

  @override
  Future<void> deleteDebt(String debtId) => localDataSource.deleteDebt(debtId);

  @override
  Stream<List<DebtRepayment>> watchRepayments(String debtId) =>
      localDataSource.watchRepayments(debtId);

  @override
  Future<void> recordRepayment(DebtRepayment repayment) =>
      localDataSource.insertRepayment(repayment);
}
