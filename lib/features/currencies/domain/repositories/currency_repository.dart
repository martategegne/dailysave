import '../entities/exchange_rate.dart';

abstract class CurrencyRepository {
  Stream<List<ExchangeRate>> watchExchangeRates();
  Future<List<ExchangeRate>> getExchangeRates();
  Future<ExchangeRate?> getRate(String fromCurrency, String toCurrency);
  Future<void> saveRate(ExchangeRate rate);
}
