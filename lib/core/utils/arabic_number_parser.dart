extension ArabicNumberParser on String {
  /// Converts Arabic-Indic (٠-٩) and Persian (۰-۹) digits to standard Western (0-9) digits.
  /// Also normalizes the Arabic decimal separator '٫' to a standard decimal dot '.'.
  String get toEnglishDigits {
    const arabicDigits = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    const persianDigits = {
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    String result = this;
    arabicDigits.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    persianDigits.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    // Normalize Arabic decimal comma '٫' to standard dot '.'
    result = result.replaceAll('٫', '.');

    return result.trim();
  }

  /// Parses this string as a double, automatically converting Arabic/Persian digits first.
  /// Returns null if the string cannot be parsed.
  double? tryParseDouble() {
    return double.tryParse(toEnglishDigits);
  }

  /// Parses this string as a double, automatically converting Arabic/Persian digits first.
  /// Throws FormatException if the string cannot be parsed.
  double parseDouble() {
    return double.parse(toEnglishDigits);
  }
}
