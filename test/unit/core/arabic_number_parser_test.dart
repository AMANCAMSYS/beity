import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/utils/arabic_number_parser.dart';

void main() {
  group('ArabicNumberParser tests', () {
    test('Should convert Arabic-Indic digits to English digits', () {
      expect('١٢٣٤٥٦٧٨٩٠'.toEnglishDigits, '1234567890');
    });

    test('Should convert Persian digits to English digits', () {
      expect('۱۲۳۴۵۶۷۸۹۰'.toEnglishDigits, '1234567890');
    });

    test('Should handle decimal separator normalize', () {
      expect('٢٫٥'.toEnglishDigits, '2.5');
      expect('١٢٫٧٥'.toEnglishDigits, '12.75');
    });

    test('Should handle mixed strings and spaces', () {
      expect('  ١٢.٥  '.toEnglishDigits, '12.5');
    });

    test('Should parse double correctly using tryParseDouble', () {
      expect('٣٫١٤'.tryParseDouble(), 3.14);
      expect('invalid'.tryParseDouble(), null);
    });

    test('Should parse double correctly using parseDouble', () {
      expect('١٠٠'.parseDouble(), 100.0);
      expect(() => 'invalid'.parseDouble(), throwsFormatException);
    });
  });
}
