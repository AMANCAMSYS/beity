import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/ai_suggestions/data/models/ai_suggestion_request_model.dart';
import 'package:sawa/features/ai_suggestions/domain/entities/ai_suggestion_request.dart';

void main() {
  group('Privacy Leak Prevention', () {
    test('AiSuggestionRequestModel does NOT include PII (emails, tokens, IDs)', () {
      const entity = AiSuggestionRequest(
        prompt: 'test prompt',
        homeType: 'family',
        listTitle: 'test list',
        existingItems: ['item1'],
        language: 'en',
      );

      final model = AiSuggestionRequestModel.fromEntity(entity);
      final json = model.toJson();

      // Allowed keys according to spec
      const allowedKeys = {
        'prompt',
        'homeType',
        'listTitle',
        'existingItems',
        'language',
      };

      // Verify no extra keys exist
      final extraKeys = json.keys.toSet().difference(allowedKeys);
      expect(extraKeys, isEmpty, reason: 'Request payload contains unauthorized fields: $extraKeys');

      // Negative check for common PII keys just in case
      final piiKeys = {
        'user_id', 'email', 'token', 'auth', 'phone', 'address', 'location'
      };
      for (final key in piiKeys) {
        expect(json.containsKey(key), isFalse, reason: 'Request payload leaked PII: $key');
      }
    });

    test('AiSuggestionRequestModel serializes correctly with minimal data', () {
      const entity = AiSuggestionRequest(
        prompt: 'test',
        homeType: 'apartment',
        listTitle: 'list',
        existingItems: [],
        language: 'ar',
      );

      final json = AiSuggestionRequestModel.fromEntity(entity).toJson();

      expect(json['prompt'], 'test');
      expect(json['homeType'], 'apartment');
      expect(json['listTitle'], 'list');
      expect(json['existingItems'], isEmpty);
      expect(json['language'], 'ar');
    });
  });
}
