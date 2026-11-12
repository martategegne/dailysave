int? parseEtbToMinorUnits(String input) {
  final value = input.trim();

  // Accept whole amounts or up to two decimal places.
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
    return null;
  }

  final parts = value.split('.');

  final whole = int.tryParse(parts[0]);

  if (whole == null || whole > 90000000000000) {
    return null;
  }

  final fraction = parts.length == 2
      ? int.parse(parts[1].padRight(2, '0'))
      : 0;

  return whole * 100 + fraction;
}