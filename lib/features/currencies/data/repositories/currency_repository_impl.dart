import '../../domain/entities/exchange_rate.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/currency_local_data_source.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final CurrencyLocalDataSource localDataSource;

  CurrencyRepositoryImpl(this.localDataSource);

  @override
  Stream<List<ExchangeRate>> watchExchangeRates() =>
      localDataSource.watchExchangeRates();

  @override
  Future<List<ExchangeRate>> getExchangeRates() =>
      localDataSource.getExchangeRates();

  @override
  Future<ExchangeRate?> getRate(String fromCurrency, String toCurrency) =>
      localDataSource.getRate(fromCurrency, toCurrency);

  @override
  Future<void> saveRate(ExchangeRate rate) =>
      localDataSource.insertRate(rate);
}
