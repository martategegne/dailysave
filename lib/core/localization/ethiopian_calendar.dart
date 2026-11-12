/// High-accuracy Ethiopian Calendar converter and Ge'ez numeral formatter.
/// Supports conversion between Gregorian (Western) and Ethiopian (Ge'ez) calendars.
/// In the Ethiopian calendar:
/// - 12 months have exactly 30 days.
/// - The 13th month (Pagume / ጳጉሜን) has 5 days in a common year, 6 in a leap year.
/// - Ethiopian New Year (Enkutatash / እንቁጣጣሽ) falls on September 11 (or Sept 12 in leap years).
class EthiopianDate {
  final int year;
  final int month; // 1 (Meskerem) to 13 (Pagume)
  final int day; // 1 to 30 (or 1 to 6 for Pagume)

  const EthiopianDate({
    required this.year,
    required this.month,
    required this.day,
  });

  static const List<String> monthNamesEn = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yakatit',
    'Megabit',
    'Miazia',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  static const List<String> monthNamesAm = [
    'መስከረም',
    'ጥቅምት',
    'ኅዳር',
    'ታኅሣሥ',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዝያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'ጳጉሜን',
  ];

  static const List<String> monthNamesOm = [
    'Fulbaana',
    'Onkololeessa',
    'Sadaasa',
    'Muddee',
    'Amajjii',
    'Guraandhala',
    'Bitooteessa',
    'Ebla',
    'Caamsaa',
    'Waxabajjii',
    'Adooleessa',
    'Hagayya',
    'Qaammee',
  ];

  /// Converts a Gregorian DateTime to EthiopianDate using Julian Day Count.
  factory EthiopianDate.fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    return _jdnToEthiopian(jdn);
  }

  /// Converts this EthiopianDate back to a Gregorian DateTime.
  DateTime toGregorian() {
    final jdn = _ethiopianToJdn(year, month, day);
    return _jdnToGregorian(jdn);
  }

  String getMonthName(String languageCode) {
    if (month < 1 || month > 13) return '';
    final index = month - 1;
    switch (languageCode) {
      case 'am':
        return monthNamesAm[index];
      case 'om':
        return monthNamesOm[index];
      default:
        return monthNamesEn[index];
    }
  }

  /// Formats the date according to selected language and numeral preference.
  String format({String language = 'en', bool useGeezNumerals = false}) {
    final monthName = getMonthName(language);
    final dayStr = useGeezNumerals ? toGeezNumeral(day) : day.toString();
    final yearStr = useGeezNumerals ? toGeezNumeral(year) : year.toString();

    if (language == 'am') {
      return '$monthName $dayStr ቀን $yearStr ዓ.ም';
    } else if (language == 'om') {
      return '$monthName $dayStr, $yearStr';
    }
    return '$monthName $dayStr, $yearStr';
  }

  // --- Julian Day Number (JDN) Algorithmic Transformations ---

  static const int _ethiopianEpoch = 1724220;

  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + ((153 * m + 2) ~/ 5) + 365 * y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + (m ~/ 10);

    return DateTime(year, month, day);
  }

  static EthiopianDate _jdnToEthiopian(int jdn) {
    final j = jdn - _ethiopianEpoch;
    final year = (4 * j + 1463) ~/ 1461;
    final dayOfYear = j - (365 * (year - 1) + (year ~/ 4));
    final month = (dayOfYear ~/ 30) + 1;
    final day = (dayOfYear % 30) + 1;

    return EthiopianDate(year: year, month: month, day: day);
  }

  static int _ethiopianToJdn(int year, int month, int day) {
    return _ethiopianEpoch + 365 * (year - 1) + (year ~/ 4) + 30 * (month - 1) + day - 1;
  }

  /// Converts an integer (1 to 9999) to its standard Ge'ez numeral representation.
  static String toGeezNumeral(int number) {
    if (number <= 0) return number.toString();

    final ones = ['', '፩', '፪', '፫', '፬', '፭', '፮', '፯', '፰', '፱'];
    final tens = ['', '፲', '፳', '፴', '፵', '፶', '፷', '፸', '፹', '፺'];

    if (number < 10) return ones[number];
    if (number < 100) {
      return '${tens[number ~/ 10]}${ones[number % 10]}';
    }

    // Numbers 100-9999
    final hundreds = number ~/ 100;
    final remainder = number % 100;

    String hundredPrefix = '';
    if (hundreds > 1) {
      hundredPrefix = toGeezNumeral(hundreds);
    }

    String remainderStr = '';
    if (remainder > 0) {
      remainderStr = toGeezNumeral(remainder);
    }

    return '${hundredPrefix}፻$remainderStr';
  }
}

/// Localized currency formatting helper for Ethiopian Birr (ETB).
class CurrencyFormatter {
  static String formatBirr(int amountCents, {String locale = 'en'}) {
    final double amount = amountCents / 100.0;
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final decimalPart = parts[1];

    if (locale == 'am') {
      return '$integerPart.$decimalPart ብር';
    } else if (locale == 'om') {
      return 'ETB $integerPart.$decimalPart';
    }
    return 'ETB $integerPart.$decimalPart';
  }
}
