import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/financial_report.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics (ሪፖርት)'),
        elevation: 0,
      ),
      body: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state.exportMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.exportMessage!),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.expenseWarning,
              ),
            );
          }
        },
        builder: (context, state) {
          final report = state.report;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selection Chips
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ReportPeriod.values.map((period) {
                            final isSelected = state.selectedPeriod == period;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(period.name.toUpperCase()),
                                selected: isSelected,
                                selectedColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primaryGreen : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    if (period == ReportPeriod.custom) {
                                      _pickCustomDateRange(context);
                                    } else {
                                      context.read<ReportBloc>().add(
                                            ReportPeriodChanged(period: period),
                                          );
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Export Buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      label: const Text('Export CSV'),
                      onPressed: state.isExporting
                          ? null
                          : () {
                              context.read<ReportBloc>().add(const ReportExportCsvRequested());
                            },
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Export Printable / PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: state.isExporting
                          ? null
                          : () {
                              context.read<ReportBloc>().add(const ReportExportPdfRequested());
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (report == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Date range label
                  Text(
                    'Period: ${DateFormat.yMMMd().format(report.startDate)} — ${DateFormat.yMMMd().format(report.endDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // High-level summary metrics
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ReportMetricCard(
                        title: 'Total Operating Income',
                        value: '${report.formattedTotalIncome} ETB',
                        color: AppColors.success,
                        icon: Icons.arrow_downward,
                      ),
                      _ReportMetricCard(
                        title: 'Total Operating Expenses',
                        value: '${report.formattedTotalExpense} ETB',
                        color: AppColors.expenseWarning,
                        icon: Icons.arrow_upward,
                      ),
                      _ReportMetricCard(
                        title: 'Net Savings',
                        value: '${report.formattedNetSavings} ETB',
                        color: report.netSavingsCents >= 0
                            ? AppColors.primaryGreen
                            : AppColors.expenseWarning,
                        icon: Icons.savings_outlined,
                      ),
                      _ReportMetricCard(
                        title: 'Savings Rate',
                        value: '${report.savingsRate.toStringAsFixed(1)}%',
                        color: AppColors.darkNavy,
                        icon: Icons.pie_chart_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Category Breakdown Section
                  const Text(
                    'Category Spending Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (report.categoryBreakdown.isEmpty)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No expense transactions recorded in this period.'),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: report.categoryBreakdown.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.category,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${item.formattedAmount} ETB (${item.percentageOfTotal.toStringAsFixed(1)}%)',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (item.percentageOfTotal / 100).clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.expenseWarning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Transactions Audited
                  Text(
                    'Transactions in Period (${report.transactions.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (report.transactions.isEmpty)
                    const Text('No transactions recorded.')
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: report.transactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = report.transactions[index];
                        final isIncome = tx.type.name == 'income';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tx.description.isNotEmpty ? tx.description : tx.category),
                          subtitle: Text(
                            '${DateFormat.yMMMd().format(tx.date)} &bull; ${tx.category}',
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${tx.formattedAmount} ETB',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncome ? AppColors.success : AppColors.expenseWarning,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (range != null && context.mounted) {
      context.read<ReportBloc>().add(
            ReportPeriodChanged(
              period: ReportPeriod.custom,
              customStart: range.start,
              customEnd: DateTime(
                range.end.year,
                range.end.month,
                range.end.day,
                23,
                59,
                59,
              ),
            ),
          );
    }
  }
}

class _ReportMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _ReportMetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
