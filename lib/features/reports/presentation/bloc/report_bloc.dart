import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/file_saver.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../goals/domain/entities/financial_goal.dart';
import '../../../goals/domain/repositories/goal_repository.dart';
import '../../../transactions/domain/entities/financial_transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/services/pdf_report_generator.dart';
import '../../domain/services/report_generator_service.dart';
import 'report_event.dart';
import 'report_state.dart';

class _ReportDataUpdated extends ReportEvent {
  final List<FinancialTransaction> transactions;
  final List<Budget> budgets;
  final List<FinancialGoal> goals;

  const _ReportDataUpdated(this.transactions, this.budgets, this.goals);

  @override
  List<Object?> get props => [transactions, budgets, goals];
}

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final TransactionRepository transactionRepository;
  final BudgetRepository budgetRepository;
  final GoalRepository goalRepository;
  final ReportGeneratorService reportGenerator;
  final PrintableReportGenerator printableReportGenerator;

  StreamSubscription<List<FinancialTransaction>>? _txSub;
  List<FinancialTransaction> _latestTx = [];
  List<Budget> _latestBudgets = [];
  List<FinancialGoal> _latestGoals = [];

  ReportBloc({
    required this.transactionRepository,
    required this.budgetRepository,
    required this.goalRepository,
    this.reportGenerator = const ReportGeneratorService(),
    this.printableReportGenerator = const PrintableReportGenerator(),
  }) : super(const ReportState()) {
    on<ReportPeriodChanged>(_onPeriodChanged);
    on<_ReportDataUpdated>(_onDataUpdated);
    on<ReportExportCsvRequested>(_onExportCsv);
    on<ReportExportPdfRequested>(_onExportPdf);

    _init();
  }

  void _init() {
    _txSub = transactionRepository.watchTransactions().listen((txList) async {
      _latestTx = txList;
      _latestBudgets = await budgetRepository.getBudgets();
      _latestGoals = await goalRepository.getGoals();
      add(_ReportDataUpdated(_latestTx, _latestBudgets, _latestGoals));
    });
  }

  void _onDataUpdated(
    _ReportDataUpdated event,
    Emitter<ReportState> emit,
  ) {
    final report = reportGenerator.generate(
      period: state.selectedPeriod,
      allTransactions: event.transactions,
      budgets: event.budgets,
      goals: event.goals,
      customStart: state.customStart,
      customEnd: state.customEnd,
    );

    emit(state.copyWith(
      status: ReportStatus.success,
      report: report,
    ));
  }

  Future<void> _onPeriodChanged(
    ReportPeriodChanged event,
    Emitter<ReportState> emit,
  ) async {
    emit(state.copyWith(
      selectedPeriod: event.period,
      customStart: event.customStart,
      customEnd: event.customEnd,
    ));

    final report = reportGenerator.generate(
      period: event.period,
      allTransactions: _latestTx,
      budgets: _latestBudgets,
      goals: _latestGoals,
      customStart: event.customStart,
      customEnd: event.customEnd,
    );

    emit(state.copyWith(
      status: ReportStatus.success,
      report: report,
    ));
  }

  Future<void> _onExportCsv(
    ReportExportCsvRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (state.report == null) return;
    emit(state.copyWith(isExporting: true, exportMessage: null));

    try {
      final csvContent = state.report!.toCsv();
      final filename =
          'dailysave_report_${state.report!.period.name}_${DateTime.now().millisecondsSinceEpoch}.csv';

      await downloadReportFile(
        filename: filename,
        content: csvContent,
        mimeType: 'text/csv',
      );

      emit(state.copyWith(
        isExporting: false,
        exportMessage: 'CSV Report exported successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to export CSV: $e',
      ));
    }
  }

  Future<void> _onExportPdf(
    ReportExportPdfRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (state.report == null) return;
    emit(state.copyWith(isExporting: true, exportMessage: null));

    try {
      final htmlContent = printableReportGenerator.generateHtmlReport(state.report!);
      final filename =
          'dailysave_report_${state.report!.period.name}_${DateTime.now().millisecondsSinceEpoch}.html';

      await downloadReportFile(
        filename: filename,
        content: htmlContent,
        mimeType: 'text/html',
      );

      emit(state.copyWith(
        isExporting: false,
        exportMessage: 'Printable Report exported successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to export Report: $e',
      ));
    }
  }

  @override
  Future<void> close() async {
    await _txSub?.cancel();
    return super.close();
  }
}
