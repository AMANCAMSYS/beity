import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/ai_suggestions/domain/entities/ai_suggestion.dart';

void main() {
  group('Duplicate Detection Logic', () {
    bool isDuplicate(AiSuggestion suggestion, List<String> existingItemNames) {
      final suggestionNameClean = suggestion.name.trim().toLowerCase();
      return existingItemNames.any(
        (name) => name.trim().toLowerCase() == suggestionNameClean,
      );
    }

    test('detects exact match', () {
      const suggestion = AiSuggestion(name: 'Milk');
      final existing = ['Milk', 'Bread'];
      expect(isDuplicate(suggestion, existing), isTrue);
    });

    test('detects case-insensitive match', () {
      const suggestion = AiSuggestion(name: 'milk');
      final existing = ['Milk', 'Bread'];
      expect(isDuplicate(suggestion, existing), isTrue);
    });

    test('detects match with whitespace', () {
      const suggestion = AiSuggestion(name: '  Milk  ');
      final existing = ['Milk', 'Bread'];
      expect(isDuplicate(suggestion, existing), isTrue);
    });

    test('detects match in existing with whitespace', () {
      const suggestion = AiSuggestion(name: 'Milk');
      final existing = ['  Milk  ', 'Bread'];
      expect(isDuplicate(suggestion, existing), isTrue);
    });

    test('does not flag partial match as duplicate', () {
      const suggestion = AiSuggestion(name: 'Chicken');
      final existing = ['Chicken breast', 'Bread'];
      expect(isDuplicate(suggestion, existing), isFalse);
    });

    test('handles Arabic names correctly', () {
      const suggestion = AiSuggestion(name: 'حليب');
      final existing = ['حليب', 'خبز'];
      expect(isDuplicate(suggestion, existing), isTrue);
    });

    test('handles empty existing list', () {
      const suggestion = AiSuggestion(name: 'Milk');
      final existing = <String>[];
      expect(isDuplicate(suggestion, existing), isFalse);
    });
  });
}
