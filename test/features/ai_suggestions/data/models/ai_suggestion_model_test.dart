import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/ai_suggestions/data/models/ai_suggestion_model.dart';

void main() {
  group('AiSuggestionModel', () {
    test('fromJson parses valid suggestion correctly', () {
      final json = {
        'name': ' Milk ',
        'quantity': 2.0,
        'unit': 'liters',
        'category': 'Dairy',
        'reason': 'Essential for breakfast',
      };

      final model = AiSuggestionModel.fromJson(json);

      expect(model.name, 'Milk');
      expect(model.quantity, 2.0);
      expect(model.unit, 'liters');
      expect(model.category, 'Dairy');
      expect(model.reason, 'Essential for breakfast');
    });

    test('fromJson handles missing optional fields', () {
      final json = {'name': 'Bread'};

      final model = AiSuggestionModel.fromJson(json);

      expect(model.name, 'Bread');
      expect(model.quantity, 1.0); // Default
      expect(model.unit, isNull);
      expect(model.category, isNull);
      expect(model.reason, isNull);
    });

    test('fromJson truncates name to 100 chars', () {
      final longName = 'A' * 150;
      final json = {'name': longName};

      final model = AiSuggestionModel.fromJson(json);

      expect(model.name.length, 100);
      expect(model.name, 'A' * 100);
    });

    test('fromJson defaults quantity to 1.0 when null/invalid', () {
      final json1 = {'name': 'Milk', 'quantity': null};
      final json2 = {'name': 'Milk', 'quantity': -5.0};
      final json3 = {'name': 'Milk', 'quantity': 'invalid'};

      expect(AiSuggestionModel.fromJson(json1).quantity, 1.0);
      expect(AiSuggestionModel.fromJson(json2).quantity, 1.0);
      expect(AiSuggestionModel.fromJson(json3).quantity, 1.0);
    });

    test('fromJson handles empty name gracefully', () {
      final json = {'name': '   '};

      final model = AiSuggestionModel.fromJson(json);

      expect(model.name, '');
    });

    test('toEntity converts correctly', () {
      const model = AiSuggestionModel(
        name: 'Eggs',
        quantity: 12.0,
        unit: 'pcs',
        category: 'Dairy',
        reason: 'Good source of protein',
      );

      final entity = model.toEntity();

      expect(entity.name, 'Eggs');
      expect(entity.quantity, 12.0);
      expect(entity.unit, 'pcs');
      expect(entity.category, 'Dairy');
      expect(entity.reason, 'Good source of protein');
    });
  });
}
