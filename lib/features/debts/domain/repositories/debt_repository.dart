import '../entities/debt.dart';

abstract class DebtRepository {
  Stream<List<Debt>> watchDebts();
  Future<List<Debt>> getDebts();
  Future<void> addDebt(Debt debt);
  Future<void> updateDebt(Debt debt);
  Future<void> deleteDebt(String debtId);

  Stream<List<DebtRepayment>> watchRepayments(String debtId);
  Future<void> recordRepayment(DebtRepayment repayment);
}
