import 'package:flutter_test/flutter_test.dart';
import 'package:dailysave/core/localization/ethiopian_calendar.dart';

void main() {
  group('Ethiopian Calendar & Ge\'ez Numerals Suite', () {
    test('Converts Gregorian September 11, 2023 to Meskerem 1, 2016', () {
      final gregDate = DateTime(2023, 9, 11);
      final ethDate = EthiopianDate.fromGregorian(gregDate);

      expect(ethDate.month, 1); // Meskerem
      expect(ethDate.day, 1);
      expect(ethDate.year, 2016);
    });

    test('Round-trip conversion preserves exact dates', () {
      final original = DateTime(2024, 5, 28);
      final eth = EthiopianDate.fromGregorian(original);
      final roundTrip = eth.toGregorian();

      expect(roundTrip.year, original.year);
      expect(roundTrip.month, original.month);
      expect(roundTrip.day, original.day);
    });

    test('Formats date in Amharic, Afaan Oromo, and English', () {
      const eth = EthiopianDate(year: 2017, month: 1, day: 1);

      expect(eth.format(language: 'am'), 'መስከረም 1 ቀን 2017 ዓ.ም');
      expect(eth.format(language: 'om'), 'Fulbaana 1, 2017');
      expect(eth.format(language: 'en'), 'Meskerem 1, 2017');
    });

    test('Converts numbers to Ge\'ez numerals accurately', () {
      expect(EthiopianDate.toGeezNumeral(1), '፩');
      expect(EthiopianDate.toGeezNumeral(5), '፭');
      expect(EthiopianDate.toGeezNumeral(10), '፲');
      expect(EthiopianDate.toGeezNumeral(25), '፳፭');
      expect(EthiopianDate.toGeezNumeral(100), '፻');
    });

    test('Formats currency with proper grouping and currency symbols', () {
      expect(CurrencyFormatter.formatBirr(125050, locale: 'en'), 'ETB 1,250.50');
      expect(CurrencyFormatter.formatBirr(125050, locale: 'am'), '1,250.50 ብር');
    });
  });
}
