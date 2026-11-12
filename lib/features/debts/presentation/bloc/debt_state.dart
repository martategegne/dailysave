import 'package:equatable/equatable.dart';

import '../../domain/entities/debt.dart';

enum DebtStatus { initial, loading, success, failure }

class DebtState extends Equatable {
  final DebtStatus status;
  final List<Debt> debts;
  final String? errorMessage;

  const DebtState({
    this.status = DebtStatus.initial,
    this.debts = const [],
    this.errorMessage,
  });

  /// Debts where user borrowed money from others (liability).
  List<Debt> get borrowedDebts =>
      debts.where((d) => d.debtType == DebtType.borrowed).toList();

  /// Debts where user lent money to others (receivable).
  List<Debt> get lentDebts =>
      debts.where((d) => d.debtType == DebtType.lent).toList();

  /// Total outstanding amount user owes to others.
  int get totalBorrowedOutstandingCents => borrowedDebts
      .where((d) => !d.isSettled)
      .fold(0, (sum, d) => sum + d.remainingAmountInCents);

  /// Total outstanding amount others owe to user.
  int get totalLentOutstandingCents => lentDebts
      .where((d) => !d.isSettled)
      .fold(0, (sum, d) => sum + d.remainingAmountInCents);

  /// Debts that have passed their due date and remain unsettled.
  List<Debt> get overdueDebts {
    final now = DateTime.now();
    return debts.where((d) => d.isOverdue(now)).toList();
  }

  /// Debts settled in full.
  List<Debt> get settledDebts => debts.where((d) => d.isSettled).toList();

  /// Debts currently active (not yet fully settled).
  List<Debt> get activeDebts => debts.where((d) => !d.isSettled).toList();

  DebtState copyWith({
    DebtStatus? status,
    List<Debt>? debts,
    String? errorMessage,
  }) {
    return DebtState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, debts, errorMessage];
}
