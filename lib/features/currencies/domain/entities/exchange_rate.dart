import 'package:equatable/equatable.dart';

/// Domain entity representing a foreign exchange rate with effective date.
/// Base currency is ETB.
class ExchangeRate extends Equatable {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double rate; // e.g. 1 USD = 145.50 ETB
  final DateTime effectiveDate;
  final DateTime createdAt;

  const ExchangeRate({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.effectiveDate,
    required this.createdAt,
  });

  /// Converts an amount in minor units from [fromCurrency] to [toCurrency].
  int convertAmountInCents(int fromCents) {
    if (fromCurrency == toCurrency) return fromCents;
    return (fromCents * rate).round();
  }

  @override
  List<Object?> get props => [id, fromCurrency, toCurrency, rate, effectiveDate, createdAt];
}
