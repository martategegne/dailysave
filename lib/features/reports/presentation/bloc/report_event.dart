import 'package:equatable/equatable.dart';

import '../../domain/entities/financial_report.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class ReportPeriodChanged extends ReportEvent {
  final ReportPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;

  const ReportPeriodChanged({
    required this.period,
    this.customStart,
    this.customEnd,
  });

  @override
  List<Object?> get props => [period, customStart, customEnd];
}

class ReportExportCsvRequested extends ReportEvent {
  const ReportExportCsvRequested();
}

class ReportExportPdfRequested extends ReportEvent {
  const ReportExportPdfRequested();
}
