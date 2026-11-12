import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/accessibility/accessibility_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../transactions/domain/entities/financial_transaction.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/presentation/pages/add_edit_transaction_page.dart';
import '../../../transactions/presentation/widgets/transaction_detail_modal.dart';
import '../widgets/income_expense_chart.dart';

/// The primary responsive financial dashboard for DailySave.
/// Adapts seamlessly across Desktop, Tablet, and Mobile browser windows
/// and adheres strictly to Material 3 and WCAG 2.1 AA accessibility standards.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100;
    return 'ETB ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      body: Row(
        children: [
          // Desktop & Tablet Navigation Rail
          if (isDesktop || isTablet)
            NavigationRail(
              selectedIndex: _currentNavIndex,
              extended: isDesktop,
              minExtendedWidth: 200,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.savings_outlined, color: Colors.white, size: 24),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 12),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: Text(l10n.dashboard),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: Text(l10n.transactions),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.account_balance_outlined),
                  selectedIcon: const Icon(Icons.account_balance),
                  label: Text(l10n.savings),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.pie_chart_outline),
                  selectedIcon: const Icon(Icons.pie_chart),
                  label: Text(l10n.budgets),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.flag_outlined),
                  selectedIcon: Icon(Icons.flag),
                  label: Text('Goals'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake),
                  label: Text('Debts'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.bar_chart_outlined),
                  selectedIcon: const Icon(Icons.bar_chart),
                  label: Text(l10n.reports),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Accounts'),
                ),
              ],
              onDestinationSelected: (index) {
                if (index == 1) {
                  context.push(AppRouter.transactionsPath);
                } else if (index == 2) {
                  context.push(AppRouter.savingsPath);
                } else if (index == 3) {
                  context.push(AppRouter.budgetsPath);
                } else if (index == 4) {
                  context.push(AppRouter.goalsPath);
                } else if (index == 5) {
                  context.push(AppRouter.debtsPath);
                } else if (index == 6) {
                  context.push(AppRouter.reportsPath);
                } else if (index == 7) {
                  context.push(AppRouter.accountsPath);
                } else {
                  setState(() => _currentNavIndex = index);
                }
              },
            ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Application Header
                _buildHeader(context, l10n, isDark),

                // Dashboard Body
                Expanded(
                  child: BlocBuilder<TransactionBloc, TransactionState>(
                    builder: (context, state) {
                      final now = DateTime.now();
                      final todaySavings = state.dailySavings(now);
                      final todayIncome = state.dailyIncome(now);
                      final todayExpenses = state.dailyExpenses(now);

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 32.0 : 16.0,
                          vertical: 24.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting & Tagline Banner
                            _buildHeroBanner(context, l10n, isDark),
                            const SizedBox(height: 24),

                            // 4 Key Financial Metrics (Income, Expense, Daily Savings, Accumulated Savings)
                            _buildMetricsGrid(
                              context,
                              l10n,
                              todayIncome: todayIncome,
                              todayExpenses: todayExpenses,
                              todaySavings: todaySavings,
                              accumulatedSavings: state.accumulatedSavings,
                              savingsPercentage: state.savingsPercentage,
                              isDesktop: isDesktop,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 28),

                            // Charts and Savings Overview Section
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final weeklyData = _generateWeeklyData(state);
                                if (constraints.maxWidth > 850) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: IncomeExpenseChart(weeklyData: weeklyData),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 4,
                                        child: _buildSavingsOverviewCard(
                                          context,
                                          l10n,
                                          state,
                                          isDark,
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      IncomeExpenseChart(weeklyData: weeklyData),
                                      const SizedBox(height: 20),
                                      _buildSavingsOverviewCard(
                                        context,
                                        l10n,
                                        state,
                                        isDark,
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 32),

                            // Recent Transactions List
                            _buildRecentTransactionsSection(context, l10n, state, isDark),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? NavigationBar(
              selectedIndex: _currentNavIndex.clamp(0, 4),
              onDestinationSelected: (index) {
                if (index == 1) {
                  context.push(AppRouter.transactionsPath);
                } else if (index == 2) {
                  context.push(AppRouter.savingsPath);
                } else if (index == 3) {
                  context.push(AppRouter.budgetsPath);
                } else if (index == 4) {
                  context.push(AppRouter.reportsPath);
                } else {
                  setState(() => _currentNavIndex = index);
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: l10n.dashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: l10n.transactions,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_outlined),
                  selectedIcon: const Icon(Icons.account_balance),
                  label: l10n.savings,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.pie_chart_outline),
                  selectedIcon: const Icon(Icons.pie_chart),
                  label: l10n.budgets,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bar_chart_outlined),
                  selectedIcon: const Icon(Icons.bar_chart),
                  label: l10n.reports,
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditTransactionPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addTransaction),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.financialOverview,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Currency Pill (ETB)
          Semantics(
            label: 'Active Currency: Ethiopian Birr',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.currency_exchange, size: 14, color: AppColors.primaryGreen),
                  SizedBox(width: 4),
                  Text(
                    'ETB (ብር)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Notifications Button
          AccessibilityUtils.ensureMinTouchTarget(
            child: IconButton(
              tooltip: l10n.notifications,
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.expenseWarning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications: All daily balances up to date.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // User Profile Area
          Semantics(
            label: 'User profile: Abebe Kebede',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.darkNavy,
                      child: Text(
                        'AK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Abebe K.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tagline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.account_balance_outlined, size: 16, color: Colors.white),
                label: const Text('Savings (ቁጠባ)', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide.none,
                onPressed: () => context.push(AppRouter.savingsPath),
              ),
              ActionChip(
                avatar: const Icon(Icons.pie_chart_outline, size: 16, color: Colors.white),
                label: const Text('Budgets (በጀት)', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide.none,
                onPressed: () => context.push(AppRouter.budgetsPath),
              ),
              ActionChip(
                avatar: const Icon(Icons.flag_outlined, size: 16, color: Colors.white),
                label: const Text('Goals (ግብ)', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide.none,
                onPressed: () => context.push(AppRouter.goalsPath),
              ),
              ActionChip(
                avatar: const Icon(Icons.handshake_outlined, size: 16, color: Colors.white),
                label: const Text('Debts (ዕዳ)', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide.none,
                onPressed: () => context.push(AppRouter.debtsPath),
              ),
              ActionChip(
                avatar: const Icon(Icons.bar_chart_outlined, size: 16, color: Colors.white),
                label: const Text('Reports (ሪፖርት)', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide.none,
                onPressed: () => context.push(AppRouter.reportsPath),
              ),
              ActionChip(
                avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.white),
                label: const Text('Accounts (ሂሳቦች)', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide.none,
                onPressed: () => context.push(AppRouter.accountsPath),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    AppLocalizations l10n, {
    required int todayIncome,
    required int todayExpenses,
    required int todaySavings,
    required int accumulatedSavings,
    required double savingsPercentage,
    required bool isDesktop,
    required bool isTablet,
  }) {
    final cards = [
      _MetricCard(
        title: l10n.dailySavings,
        amountText: _formatMoney(todaySavings),
        screenReaderAmount: AccessibilityUtils.formatCurrencyForScreenReader(todaySavings),
        subtitle: 'Today Net (Income - Expenses)',
        icon: Icons.savings,
        iconColor: AppColors.primaryGreen,
        isHighlighted: true,
      ),
      _MetricCard(
        title: l10n.totalIncome,
        amountText: _formatMoney(todayIncome),
        screenReaderAmount: AccessibilityUtils.formatCurrencyForScreenReader(todayIncome),
        subtitle: "Today's Inflow (↑)",
        icon: Icons.arrow_downward,
        iconColor: AppColors.success,
      ),
      _MetricCard(
        title: l10n.totalExpenses,
        amountText: _formatMoney(todayExpenses),
        screenReaderAmount: AccessibilityUtils.formatCurrencyForScreenReader(todayExpenses),
        subtitle: "Today's Outflow (↓)",
        icon: Icons.arrow_upward,
        iconColor: AppColors.expenseWarning,
      ),
      _MetricCard(
        title: l10n.accumulatedSavings,
        amountText: _formatMoney(accumulatedSavings),
        screenReaderAmount: AccessibilityUtils.formatCurrencyForScreenReader(accumulatedSavings),
        subtitle: 'Rate: ${savingsPercentage.toStringAsFixed(1)}% of income',
        icon: Icons.account_balance,
        iconColor: AppColors.infoBlue,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: card,
                  ),
                ))
            .toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: card,
                ))
            .toList(),
      );
    }
  }

  Widget _buildSavingsOverviewCard(
    BuildContext context,
    AppLocalizations l10n,
    TransactionState state,
    bool isDark,
  ) {
    final double rate = state.savingsPercentage.clamp(0.0, 100.0);
    final targetSavings = 5000000; // 50,000 ETB target
    final double progress = (state.accumulatedSavings / targetSavings).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.savingsOverview,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Daily Savings Rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.savingsRate,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: isDark ? AppColors.surfaceDarkVariant : AppColors.borderLight,
              color: AppColors.primaryGreen,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),

            // Emergency Fund Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Reserve Goal',
                  style: TextStyle(fontSize: 13),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavyLight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? AppColors.surfaceDarkVariant : AppColors.borderLight,
              color: AppColors.darkNavyLight,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatMoney(state.accumulatedSavings)} / ${_formatMoney(targetSavings)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    AppLocalizations l10n,
    TransactionState state,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentTransactions,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${state.transactions.length} entries',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (state.transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.textMutedLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noTransactions,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.startTracking,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = state.transactions[index];
              final isIncome = tx.type == TransactionType.income;
              final sign = isIncome ? '+' : '-';
              final formattedAmount = '$sign${_formatMoney(tx.amountInCents)}';
              final typeLabel = isIncome ? '[Income]' : '[Expense]';

              return Semantics(
                label:
                    'Transaction: ${tx.category}, ${tx.description}, $typeLabel, ${AccessibilityUtils.formatCurrencyForScreenReader(tx.amountInCents)}',
                child: Card(
                  child: ListTile(
                    onTap: () => TransactionDetailModal.show(context, tx),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.expenseWarning.withValues(alpha: 0.12),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? AppColors.success : AppColors.expenseWarning,
                        size: 20,
                      ),
                    ),
                    title: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          tx.category,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isIncome
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.expenseWarning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isIncome ? AppColors.success : AppColors.expenseWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      tx.description.isNotEmpty ? tx.description : 'No description provided',
                      style: TextStyle(
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formattedAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isIncome ? AppColors.success : AppColors.expenseWarning,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Delete transaction',
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () {
                            context.read<TransactionBloc>().add(TransactionDeleted(tx.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction deleted.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Map<String, ({int income, int expense})> _generateWeeklyData(TransactionState state) {
    final Map<String, ({int income, int expense})> data = {};
    final now = DateTime.now();
    final weekDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = weekDayNames[date.weekday - 1];
      data[dayName] = (
        income: state.dailyIncome(date),
        expense: state.dailyExpenses(date),
      );
    }
    return data;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String amountText;
  final String screenReaderAmount;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isHighlighted;

  const _MetricCard({
    required this.title,
    required this.amountText,
    required this.screenReaderAmount,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: '$title: $screenReaderAmount. $subtitle',
      child: Card(
        color: isHighlighted
            ? (isDark ? AppColors.darkNavy : AppColors.primaryGreen)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isHighlighted
                          ? Colors.white70
                          : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? Colors.white.withValues(alpha: 0.15)
                          : iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isHighlighted ? Colors.white : iconColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isHighlighted
                      ? Colors.white70
                      : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
