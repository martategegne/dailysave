import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Accessible visual chart comparing Income and Expenses over the last 7 days.
/// Complies with WCAG 2.1 AA by providing a complete semantic description
/// for screen-readers and high-contrast color coding with distinct shapes/labels.
class IncomeExpenseChart extends StatelessWidget {
  final Map<String, ({int income, int expense})> weeklyData;

  const IncomeExpenseChart({
    super.key,
    required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    // Generate semantic string for screen-reader users
    final buffer = StringBuffer('Income and expense summary for the past 7 days: ');
    weeklyData.forEach((day, data) {
      final inc = (data.income / 100).toStringAsFixed(0);
      final exp = (data.expense / 100).toStringAsFixed(0);
      buffer.write('$day: $inc Birr income, $exp Birr expense. ');
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Financial Trend Chart',
      value: buffer.toString(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income & Expense Trend',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last 7 Days Activity (ETB)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                  // Visual Legend (Color + Symbol for Accessibility)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendItem(
                        color: AppColors.success,
                        label: 'Income (↑)',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildLegendItem(
                        color: AppColors.expenseWarning,
                        label: 'Expense (↓)',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _ChartPainter(
                    data: weeklyData,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Map<String, ({int income, int expense})> data;
  final bool isDark;

  _ChartPainter({
    required this.data,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double bottomPadding = 24.0;
    final double chartHeight = size.height - bottomPadding;
    final int count = data.length;
    final double slotWidth = size.width / count;
    final double barWidth = math.min(14.0, slotWidth * 0.28);

    // Find highest value for dynamic scaling
    int maxValInCents = 100000; // minimum baseline of 1,000 ETB
    for (final item in data.values) {
      if (item.income > maxValInCents) maxValInCents = item.income;
      if (item.expense > maxValInCents) maxValInCents = item.expense;
    }

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final incomePaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.fill;

    final expensePaint = Paint()
      ..color = AppColors.expenseWarning
      ..style = PaintingStyle.fill;

    int index = 0;
    data.forEach((dayLabel, values) {
      final centerX = slotWidth * index + (slotWidth / 2);

      // Heights
      final double incomeHeight =
          (values.income / maxValInCents) * (chartHeight - 10);
      final double expenseHeight =
          (values.expense / maxValInCents) * (chartHeight - 10);

      // Income bar (left)
      final incomeRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          centerX - barWidth - 2,
          chartHeight - incomeHeight,
          barWidth,
          incomeHeight > 0 ? incomeHeight : 2,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(incomeRect, incomePaint);

      // Expense bar (right)
      final expenseRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          centerX + 2,
          chartHeight - expenseHeight,
          barWidth,
          expenseHeight > 0 ? expenseHeight : 2,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(expenseRect, expensePaint);

      // Day label
      final textPainter = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), size.height - 18),
      );

      index++;
    });
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isDark != isDark;
  }
}
