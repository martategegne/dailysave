import 'package:equatable/equatable.dart';

import '../../domain/entities/financial_report.dart';

enum ReportStatus { initial, loading, success, failure }

class ReportState extends Equatable {
  final ReportStatus status;
  final FinancialReport? report;
  final ReportPeriod selectedPeriod;
  final DateTime? customStart;
  final DateTime? customEnd;
  final bool isExporting;
  final String? exportMessage;
  final String? errorMessage;

  const ReportState({
    this.status = ReportStatus.initial,
    this.report,
    this.selectedPeriod = ReportPeriod.monthly,
    this.customStart,
    this.customEnd,
    this.isExporting = false,
    this.exportMessage,
    this.errorMessage,
  });

  ReportState copyWith({
    ReportStatus? status,
    FinancialReport? report,
    ReportPeriod? selectedPeriod,
    DateTime? customStart,
    DateTime? customEnd,
    bool? isExporting,
    String? exportMessage,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      report: report ?? this.report,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      isExporting: isExporting ?? this.isExporting,
      exportMessage: exportMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        report,
        selectedPeriod,
        customStart,
        customEnd,
        isExporting,
        exportMessage,
        errorMessage,
      ];
}
