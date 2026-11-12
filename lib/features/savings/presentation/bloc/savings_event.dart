import 'package:equatable/equatable.dart';

abstract class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object?> get props => [];
}

class SavingsSubscriptionRequested extends SavingsEvent {
  const SavingsSubscriptionRequested();
}

class SavingsDepositSubmitted extends SavingsEvent {
  final int amountInCents;
  final String savingsAccount;
  final String sourceAccount;
  final String description;
  final DateTime date;

  const SavingsDepositSubmitted({
    required this.amountInCents,
    required this.savingsAccount,
    required this.sourceAccount,
    required this.description,
    required this.date,
  });

  @override
  List<Object?> get props => [amountInCents, savingsAccount, sourceAccount, description, date];
}

class SavingsWithdrawalSubmitted extends SavingsEvent {
  final int amountInCents;
  final String savingsAccount;
  final String targetAccount;
  final String description;
  final DateTime date;

  const SavingsWithdrawalSubmitted({
    required this.amountInCents,
    required this.savingsAccount,
    required this.targetAccount,
    required this.description,
    required this.date,
  });

  @override
  List<Object?> get props => [amountInCents, savingsAccount, targetAccount, description, date];
}
