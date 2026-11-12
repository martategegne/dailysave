import 'package:equatable/equatable.dart';

import '../../domain/entities/debt.dart';

abstract class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => [];
}

class DebtSubscriptionRequested extends DebtEvent {
  const DebtSubscriptionRequested();
}

class DebtAdded extends DebtEvent {
  final Debt debt;
  const DebtAdded(this.debt);

  @override
  List<Object?> get props => [debt];
}

class DebtUpdated extends DebtEvent {
  final Debt debt;
  const DebtUpdated(this.debt);

  @override
  List<Object?> get props => [debt];
}

class DebtDeleted extends DebtEvent {
  final String debtId;
  const DebtDeleted(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

class DebtRepaymentSubmitted extends DebtEvent {
  final DebtRepayment repayment;
  const DebtRepaymentSubmitted(this.repayment);

  @override
  List<Object?> get props => [repayment];
}
