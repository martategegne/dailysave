import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../database/app_database.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/debts/presentation/pages/debts_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/savings/presentation/pages/savings_page.dart';
import '../../features/transactions/presentation/pages/transaction_history_page.dart';

/// Navigation and deep linking configuration powered by GoRouter.
/// Ensures standard URL paths for Flutter Web and native back-stack for mobile.
class AppRouter {
  AppRouter._();

  static const String dashboardPath = '/';
  static const String transactionsPath = '/transactions';
  static const String savingsPath = '/savings';
  static const String budgetsPath = '/budgets';
  static const String goalsPath = '/goals';
  static const String debtsPath = '/debts';
  static const String reportsPath = '/reports';
  static const String accountsPath = '/accounts';
  static const String settingsPath = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: dashboardPath,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: dashboardPath,
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: transactionsPath,
        name: 'transactions',
        builder: (context, state) => const TransactionHistoryPage(),
      ),
      GoRoute(
        path: savingsPath,
        name: 'savings',
        builder: (context, state) => const SavingsPage(),
      ),
      GoRoute(
        path: budgetsPath,
        name: 'budgets',
        builder: (context, state) => const BudgetsPage(),
      ),
      GoRoute(
        path: goalsPath,
        name: 'goals',
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: debtsPath,
        name: 'debts',
        builder: (context, state) => const DebtsPage(),
      ),
      GoRoute(
        path: reportsPath,
        name: 'reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: accountsPath,
        name: 'accounts',
        builder: (context, state) => AccountsPage(db: context.read<AppDatabase>()),
      ),
      GoRoute(
        path: settingsPath,
        name: 'settings',
        builder: (context, state) => const _PlaceholderFeaturePage(title: 'Settings'),
      ),
    ],
  );
}

class _PlaceholderFeaturePage extends StatelessWidget {
  final String title;

  const _PlaceholderFeaturePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Back to Dashboard',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.dashboardPath),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                '$title Module',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This section is part of the feature-based Clean Architecture roadmap.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRouter.dashboardPath),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
