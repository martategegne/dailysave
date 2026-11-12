import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/exchange_rate.dart';

abstract class CurrencyLocalDataSource {
  Stream<List<ExchangeRate>> watchExchangeRates();
  Future<List<ExchangeRate>> getExchangeRates();
  Future<ExchangeRate?> getRate(String fromCurrency, String toCurrency);
  Future<void> insertRate(ExchangeRate rate);
}

class CurrencyLocalDataSourceImpl implements CurrencyLocalDataSource {
  final AppDatabase db;

  CurrencyLocalDataSourceImpl(this.db);

  ExchangeRate _toDomain(ExchangeRatesTableData row) {
    return ExchangeRate(
      id: row.id,
      fromCurrency: row.fromCurrency,
      toCurrency: row.toCurrency,
      rate: row.rate,
      effectiveDate: row.effectiveDate,
      createdAt: row.createdAt,
    );
  }

  ExchangeRatesTableCompanion _toCompanion(ExchangeRate rate) {
    return ExchangeRatesTableCompanion(
      id: Value(rate.id),
      fromCurrency: Value(rate.fromCurrency),
      toCurrency: Value(rate.toCurrency),
      rate: Value(rate.rate),
      effectiveDate: Value(rate.effectiveDate),
      createdAt: Value(rate.createdAt),
    );
  }

  @override
  Stream<List<ExchangeRate>> watchExchangeRates() {
    return (db.select(db.exchangeRatesTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.effectiveDate, mode: OrderingMode.desc)
          ]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<ExchangeRate>> getExchangeRates() async {
    final rows = await (db.select(db.exchangeRatesTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.effectiveDate, mode: OrderingMode.desc)
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<ExchangeRate?> getRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return ExchangeRate(
        id: 'self_$fromCurrency',
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        rate: 1.0,
        effectiveDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    final row = await (db.select(db.exchangeRatesTable)
          ..where((t) =>
              t.fromCurrency.equals(fromCurrency) & t.toCurrency.equals(toCurrency))
          ..orderBy([
            (t) => OrderingTerm(expression: t.effectiveDate, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<void> insertRate(ExchangeRate rate) async {
    await db.into(db.exchangeRatesTable).insert(
          _toCompanion(rate),
          mode: InsertMode.insertOrReplace,
        );
  }
}
