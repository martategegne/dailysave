import '../entities/financial_report.dart';

class PrintableReportGenerator {
  const PrintableReportGenerator();

  /// Generates a complete, beautifully styled HTML document optimized for printing to PDF.
  String generateHtmlReport(FinancialReport report) {
    final buffer = StringBuffer();
    final startStr = report.startDate.toIso8601String().split('T').first;
    final endStr = report.endDate.toIso8601String().split('T').first;

    buffer.writeln('''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>DailySave Financial Report - ${report.period.name.toUpperCase()}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      margin: 40px;
      color: #172554;
      background: #FFFFFF;
    }
    .header {
      border-bottom: 2px solid #16865B;
      padding-bottom: 16px;
      margin-bottom: 24px;
    }
    .tagline {
      color: #16865B;
      font-weight: 600;
      margin-top: 4px;
    }
    .meta {
      color: #64748B;
      font-size: 14px;
      margin-top: 8px;
    }
    .summary-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
      margin-bottom: 32px;
    }
    .metric-card {
      background: #F7F9F8;
      border: 1px solid #E2E8F0;
      border-radius: 8px;
      padding: 16px;
    }
    .metric-title {
      font-size: 13px;
      color: #64748B;
      text-transform: uppercase;
      font-weight: 600;
    }
    .metric-value {
      font-size: 22px;
      font-weight: 700;
      margin-top: 6px;
    }
    .income { color: #16A34A; }
    .expense { color: #DC2626; }
    .savings { color: #16865B; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 28px;
    }
    th, td {
      border: 1px solid #E2E8F0;
      padding: 10px 14px;
      text-align: left;
      font-size: 14px;
    }
    th {
      background: #F1F5F9;
      font-weight: 600;
    }
    .section-title {
      font-size: 18px;
      font-weight: 700;
      margin-top: 24px;
      margin-bottom: 12px;
      color: #172554;
    }
    .footer {
      margin-top: 40px;
      padding-top: 16px;
      border-top: 1px solid #E2E8F0;
      font-size: 12px;
      color: #94A3B8;
      text-align: center;
    }
    @media print {
      body { margin: 20px; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1 style="margin:0; color:#172554;">DailySave Financial Report</h1>
    <div class="tagline">Track Every Birr. Understand Your Money. Build Your Future.</div>
    <div class="meta">
      <strong>Report Period:</strong> ${report.period.name.toUpperCase()} ($startStr to $endStr) &bull;
      <strong>Generated:</strong> ${DateTime.now().toLocal().toString().split('.').first}
    </div>
  </div>

  <div class="summary-grid">
    <div class="metric-card">
      <div class="metric-title">Operating Income</div>
      <div class="metric-value income">${report.formattedTotalIncome} ETB</div>
    </div>
    <div class="metric-card">
      <div class="metric-title">Operating Expenses</div>
      <div class="metric-value expense">${report.formattedTotalExpense} ETB</div>
    </div>
    <div class="metric-card">
      <div class="metric-title">Net Savings</div>
      <div class="metric-value savings">${report.formattedNetSavings} ETB</div>
    </div>
    <div class="metric-card">
      <div class="metric-title">Savings Rate</div>
      <div class="metric-value">${report.savingsRate.toStringAsFixed(1)}%</div>
    </div>
  </div>

  <div class="section-title">Category Spending Breakdown</div>
  <table>
    <thead>
      <tr>
        <th>Category</th>
        <th>Spent Amount (ETB)</th>
        <th>Percentage of Expenses</th>
      </tr>
    </thead>
    <tbody>
''');

    if (report.categoryBreakdown.isEmpty) {
      buffer.writeln('<tr><td colspan="3" style="text-align:center; color:#64748B;">No expenses recorded in this period.</td></tr>');
    } else {
      for (final item in report.categoryBreakdown) {
        buffer.writeln('''
      <tr>
        <td><strong>${item.category}</strong></td>
        <td>${item.formattedAmount} ETB</td>
        <td>${item.percentageOfTotal.toStringAsFixed(1)}%</td>
      </tr>
''');
      }
    }

    buffer.writeln('''
    </tbody>
  </table>

  <div class="section-title">Transaction Details (${report.transactions.length} records)</div>
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Type</th>
        <th>Category</th>
        <th>Description</th>
        <th>Amount (ETB)</th>
        <th>Payment / Account</th>
      </tr>
    </thead>
    <tbody>
''');

    if (report.transactions.isEmpty) {
      buffer.writeln('<tr><td colspan="6" style="text-align:center; color:#64748B;">No transactions found for this period.</td></tr>');
    } else {
      for (final tx in report.transactions) {
        final txDate = tx.date.toIso8601String().split('T').first;
        final color = tx.type.name == 'income' ? '#16A34A' : '#DC2626';
        buffer.writeln('''
      <tr>
        <td>$txDate</td>
        <td>${tx.type.name}</td>
        <td>${tx.category}</td>
        <td>${tx.description}</td>
        <td style="color:$color; font-weight:600;">${tx.formattedAmount} ETB</td>
        <td>${tx.paymentMethod} &bull; ${tx.account}</td>
      </tr>
''');
      }
    }

    buffer.writeln('''
    </tbody>
  </table>

  <div class="footer">
    DailySave &bull; Offline Financial Management &bull; Local Data Sovereignty Guaranteed
  </div>
</body>
</html>
''');

    return buffer.toString();
  }
}
