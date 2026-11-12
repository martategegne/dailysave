import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/constants/app_strings.dart';
import '../core/database/app_database.dart';
import '../core/localization/app_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/budgets/data/datasources/budget_local_data_source.dart';
import '../features/budgets/data/repositories/budget_repository_impl.dart';
import '../features/budgets/domain/repositories/budget_repository.dart';
import '../features/budgets/presentation/bloc/budget_bloc.dart';
import '../features/currencies/data/datasources/currency_local_data_source.dart';
import '../features/currencies/data/repositories/currency_repository_impl.dart';
import '../features/currencies/domain/repositories/currency_repository.dart';
import '../features/debts/data/datasources/debt_local_data_source.dart';
import '../features/debts/data/repositories/debt_repository_impl.dart';
import '../features/debts/domain/repositories/debt_repository.dart';
import '../features/debts/presentation/bloc/debt_bloc.dart';
import '../features/goals/data/datasources/goal_local_data_source.dart';
import '../features/goals/data/repositories/goal_repository_impl.dart';
import '../features/goals/domain/repositories/goal_repository.dart';
import '../features/goals/presentation/bloc/goal_bloc.dart';
import '../features/reports/presentation/bloc/report_bloc.dart';
import '../features/savings/presentation/bloc/savings_bloc.dart';
import '../features/transactions/data/datasources/transaction_local_data_source.dart';
import '../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../features/transactions/domain/repositories/transaction_repository.dart';
import '../features/transactions/presentation/bloc/transaction_bloc.dart';

/// Root application widget configuring local Drift database, Clean Architecture
/// repositories, BLoC providers, Material 3 themes, GoRouter declarative routing,
/// and tri-lingual internationalization (English, Amharic, Afaan Oromo).
class DailySaveApp extends StatefulWidget {
  final AppDatabase? database;
  final TransactionRepository? transactionRepository;
  final BudgetRepository? budgetRepository;
  final GoalRepository? goalRepository;
  final DebtRepository? debtRepository;
  final CurrencyRepository? currencyRepository;

  const DailySaveApp({
    super.key,
    this.database,
    this.transactionRepository,
    this.budgetRepository,
    this.goalRepository,
    this.debtRepository,
    this.currencyRepository,
  });

  @override
  State<DailySaveApp> createState() => _DailySaveAppState();
}

class _DailySaveAppState extends State<DailySaveApp> {
  late final AppDatabase _db;
  late final TransactionRepository _transactionRepo;
  late final BudgetRepository _budgetRepo;
  late final GoalRepository _goalRepo;
  late final DebtRepository _debtRepo;
  late final CurrencyRepository _currencyRepo;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _transactionRepo = widget.transactionRepository ??
        TransactionRepositoryImpl(TransactionLocalDataSourceImpl(_db));
    _budgetRepo = widget.budgetRepository ??
        BudgetRepositoryImpl(BudgetLocalDataSourceImpl(_db));
    _goalRepo = widget.goalRepository ??
        GoalRepositoryImpl(GoalLocalDataSourceImpl(_db));
    _debtRepo = widget.debtRepository ??
        DebtRepositoryImpl(DebtLocalDataSourceImpl(_db));
    _currencyRepo = widget.currencyRepository ??
        CurrencyRepositoryImpl(CurrencyLocalDataSourceImpl(_db));
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: _db),
        RepositoryProvider<TransactionRepository>.value(value: _transactionRepo),
        RepositoryProvider<BudgetRepository>.value(value: _budgetRepo),
        RepositoryProvider<GoalRepository>.value(value: _goalRepo),
        RepositoryProvider<DebtRepository>.value(value: _debtRepo),
        RepositoryProvider<CurrencyRepository>.value(value: _currencyRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TransactionBloc>(
            create: (context) => TransactionBloc(repository: _transactionRepo),
          ),
          BlocProvider<SavingsBloc>(
            create: (context) =>
                SavingsBloc(transactionRepository: _transactionRepo),
          ),
          BlocProvider<BudgetBloc>(
            create: (context) => BudgetBloc(
              budgetRepository: _budgetRepo,
              transactionRepository: _transactionRepo,
            ),
          ),
          BlocProvider<GoalBloc>(
            create: (context) => GoalBloc(goalRepository: _goalRepo),
          ),
          BlocProvider<DebtBloc>(
            create: (context) => DebtBloc(debtRepository: _debtRepo),
          ),
          BlocProvider<ReportBloc>(
            create: (context) => ReportBloc(
              transactionRepository: _transactionRepo,
              budgetRepository: _budgetRepo,
              goalRepository: _goalRepo,
            ),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,

          // Material 3 Themes
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // GoRouter Routing
          routerConfig: AppRouter.router,

          // Internationalization (English, Amharic, Afaan Oromo)
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
