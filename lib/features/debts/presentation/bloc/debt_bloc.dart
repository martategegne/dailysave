import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import 'debt_event.dart';
import 'debt_state.dart';

class _DebtsUpdated extends DebtEvent {
  final List<Debt> debts;
  const _DebtsUpdated(this.debts);

  @override
  List<Object?> get props => [debts];
}

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final DebtRepository debtRepository;
  StreamSubscription<List<Debt>>? _subscription;

  DebtBloc({required this.debtRepository}) : super(const DebtState()) {
    on<DebtSubscriptionRequested>(_onSubscriptionRequested);
    on<_DebtsUpdated>(_onDebtsUpdated);
    on<DebtAdded>(_onDebtAdded);
    on<DebtUpdated>(_onDebtUpdated);
    on<DebtDeleted>(_onDebtDeleted);
    on<DebtRepaymentSubmitted>(_onRepaymentSubmitted);

    add(const DebtSubscriptionRequested());
  }

  Future<void> _onSubscriptionRequested(
    DebtSubscriptionRequested event,
    Emitter<DebtState> emit,
  ) async {
    emit(state.copyWith(status: DebtStatus.loading));
    await _subscription?.cancel();
    _subscription = debtRepository.watchDebts().listen(
          (debts) => add(_DebtsUpdated(debts)),
          onError: (err) => emit(state.copyWith(
            status: DebtStatus.failure,
            errorMessage: err.toString(),
          )),
        );
  }

  void _onDebtsUpdated(
    _DebtsUpdated event,
    Emitter<DebtState> emit,
  ) {
    emit(state.copyWith(
      status: DebtStatus.success,
      debts: event.debts,
    ));
  }

  Future<void> _onDebtAdded(
    DebtAdded event,
    Emitter<DebtState> emit,
  ) async {
    await debtRepository.addDebt(event.debt);
  }

  Future<void> _onDebtUpdated(
    DebtUpdated event,
    Emitter<DebtState> emit,
  ) async {
    await debtRepository.updateDebt(event.debt);
  }

  Future<void> _onDebtDeleted(
    DebtDeleted event,
    Emitter<DebtState> emit,
  ) async {
    await debtRepository.deleteDebt(event.debtId);
  }

  Future<void> _onRepaymentSubmitted(
    DebtRepaymentSubmitted event,
    Emitter<DebtState> emit,
  ) async {
    await debtRepository.recordRepayment(event.repayment);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
