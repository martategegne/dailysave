import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Multilingual localization support for DailySave:
/// - English (en)
/// - Amharic (am - አማርኛ)
/// - Afaan Oromo (om - Afaan Oromoo)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('am'),
    Locale('om'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'DailySave',
      'tagline': 'Track Every Birr. Understand Your Money. Build Your Future.',
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'budgets': 'Budgets',
      'savings': 'Savings',
      'reports': 'Reports',
      'settings': 'Settings',
      'totalIncome': 'Total Income',
      'totalExpenses': 'Total Expenses',
      'dailySavings': "Today's Savings",
      'accumulatedSavings': 'Accumulated Savings',
      'savingsOverview': 'Savings Overview',
      'savingsRate': 'Daily Savings Rate',
      'recentTransactions': 'Recent Transactions',
      'viewAll': 'View all',
      'income': 'Income',
      'expense': 'Expense',
      'addTransaction': 'Add Transaction',
      'saveTransaction': 'Save Transaction',
      'cancel': 'Cancel',
      'amount': 'Amount (ETB)',
      'category': 'Category',
      'description': 'Description',
      'transactionType': 'Transaction Type',
      'notifications': 'Notifications',
      'userProfile': 'User Profile',
      'noTransactions': 'No transactions yet.',
      'startTracking': 'Add your first transaction to start tracking your Birr.',
      'incomeVsExpense': 'Income & Expense Trend',
      'financialOverview': 'Financial Overview',
      'currency': 'ETB',
    },
    'am': {
      'appName': 'ዴይሊሴቭ',
      'tagline': 'እያንዳንዱን ብር ይከታተሉ። ገንዘብዎን ይረዱ። የወደፊት ህይወትዎን ይገንቡ።',
      'dashboard': 'ዳሽቦርድ',
      'transactions': 'ግብይቶች',
      'budgets': 'በጀት',
      'savings': 'ቁጠባ',
      'reports': 'ሪፖርቶች',
      'settings': 'ቅንብሮች',
      'totalIncome': 'አጠቃላይ ገቢ',
      'totalExpenses': 'አጠቃላይ ወጪ',
      'dailySavings': 'የዛሬ ቁጠባ',
      'accumulatedSavings': 'የተጠራቀመ ቁጠባ',
      'savingsOverview': 'የቁጠባ አጠቃላይ እይታ',
      'savingsRate': 'የቀን ቁጠባ መጠን',
      'recentTransactions': 'የቅርብ ጊዜ ግብይቶች',
      'viewAll': 'ሁሉንም ይመልከቱ',
      'income': 'ገቢ',
      'expense': 'ወጪ',
      'addTransaction': 'ግብይት መዝግብ',
      'saveTransaction': 'አስቀምጥ',
      'cancel': 'ይቅር',
      'amount': 'መጠን (ብር)',
      'category': 'ዘርፍ',
      'description': 'መግለጫ',
      'transactionType': 'የግብይት አይነት',
      'notifications': 'ማሳወቂያዎች',
      'userProfile': 'የግል መገለጫ',
      'noTransactions': 'እስካሁን ምንም ግብይት የለም።',
      'startTracking': 'ብርዎን መከታተል ለመጀመር የመጀመሪያዎን ግብይት ያስገቡ።',
      'incomeVsExpense': 'የገቢ እና ወጪ ንፅፅር',
      'financialOverview': 'የፋይናንስ አጠቃላይ እይታ',
      'currency': 'ብር',
    },
    'om': {
      'appName': 'DailySave',
      'tagline': 'Qarshii Hundumaa Hordofi. Qabeenya Keessan Hubadhaa. Fuuldura Keessan Ijaaraa.',
      'dashboard': 'Daashboordii',
      'transactions': 'Daldaloota',
      'budgets': 'Baajata',
      'savings': 'Qusannoo',
      'reports': 'Gabaasota',
      'settings': 'Qindaa’inoota',
      'totalIncome': 'Galii Waliigalaa',
      'totalExpenses': 'Baasii Waliigalaa',
      'dailySavings': 'Qusannoo Har’aa',
      'accumulatedSavings': 'Qusannoo Walitti-qabame',
      'savingsOverview': 'Ilaalcha Qusannoo',
      'savingsRate': 'Reeshoo Qusannoo Guyyaa',
      'recentTransactions': 'Daldaloota Dhiyoo',
      'viewAll': 'Hundumaa ilaali',
      'income': 'Galii',
      'expense': 'Baasii',
      'addTransaction': 'Daldala Dabali',
      'saveTransaction': 'Olkaawi',
      'cancel': 'Dhiisi',
      'amount': 'Hanga (ETB)',
      'category': 'Koodii/Garee',
      'description': 'Ibsa',
      'transactionType': 'Gosa Daldalaa',
      'notifications': 'Beeksisa',
      'userProfile': 'Piroofaayilii',
      'noTransactions': 'Hanga ammaatti daladalli hin jiru.',
      'startTracking': 'Qarshii kee hordofuu jalqabuuf daldala kee isa duraa galchi.',
      'incomeVsExpense': 'Haala Galii fi Baasii',
      'financialOverview': 'Ilaalcha Faayinaansii',
      'currency': 'ETB',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String get appName => translate('appName');
  String get tagline => translate('tagline');
  String get dashboard => translate('dashboard');
  String get transactions => translate('transactions');
  String get budgets => translate('budgets');
  String get savings => translate('savings');
  String get reports => translate('reports');
  String get settings => translate('settings');
  String get totalIncome => translate('totalIncome');
  String get totalExpenses => translate('totalExpenses');
  String get dailySavings => translate('dailySavings');
  String get accumulatedSavings => translate('accumulatedSavings');
  String get savingsOverview => translate('savingsOverview');
  String get savingsRate => translate('savingsRate');
  String get recentTransactions => translate('recentTransactions');
  String get viewAll => translate('viewAll');
  String get income => translate('income');
  String get expense => translate('expense');
  String get addTransaction => translate('addTransaction');
  String get saveTransaction => translate('saveTransaction');
  String get cancel => translate('cancel');
  String get amount => translate('amount');
  String get category => translate('category');
  String get description => translate('description');
  String get transactionType => translate('transactionType');
  String get notifications => translate('notifications');
  String get userProfile => translate('userProfile');
  String get noTransactions => translate('noTransactions');
  String get startTracking => translate('startTracking');
  String get incomeVsExpense => translate('incomeVsExpense');
  String get financialOverview => translate('financialOverview');
  String get currency => translate('currency');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'am', 'om'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
