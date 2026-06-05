import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/ai_suggestions/domain/entities/ai_suggestion.dart';
import 'package:sawa/features/ai_suggestions/domain/entities/ai_suggestion_request.dart';
import 'package:sawa/features/ai_suggestions/domain/repositories/ai_suggestion_repository.dart';
import 'package:sawa/features/ai_suggestions/domain/usecases/get_ai_suggestions.dart';
import 'package:sawa/core/errors/app_exception.dart';

class MockAiSuggestionRepository extends Mock implements AiSuggestionRepository {}

void main() {
  late MockAiSuggestionRepository mockRepository;
  late GetAiSuggestions useCase;

  setUp(() {
    mockRepository = MockAiSuggestionRepository();
    useCase = GetAiSuggestions(mockRepository);
    
    registerFallbackValue(const AiSuggestionRequest(
      prompt: '',
      homeType: '',
      listTitle: '',
      existingItems: [],
      language: 'en',
    ));
  });

  const tSuggestions = [
    AiSuggestion(name: 'Milk'),
  ];

  group('GetAiSuggestions', () {
    test('calls repository with valid request', () async {
      when(() => mockRepository.getSuggestions(any()))
          .thenAnswer((_) async => tSuggestions);

      const request = AiSuggestionRequest(
        prompt: 'test',
        homeType: 'family',
        listTitle: 'list',
        existingItems: [],
        language: 'en',
      );

      final result = await useCase(request);

      expect(result, tSuggestions);
      verify(() => mockRepository.getSuggestions(request)).called(1);
    });

    test('throws ValidationException for empty prompt', () async {
      const request = AiSuggestionRequest(
        prompt: '  ',
        homeType: 'family',
        listTitle: 'list',
        existingItems: [],
        language: 'en',
      );

      expect(() => useCase(request), throwsA(isA<ValidationException>()));
    });

    test('throws ValidationException for prompt > 500 chars', () async {
      final request = AiSuggestionRequest(
        prompt: 'A' * 501,
        homeType: 'family',
        listTitle: 'list',
        existingItems: [],
        language: 'en',
      );

      expect(() => useCase(request), throwsA(isA<ValidationException>()));
    });

    test('throws ValidationException for invalid language', () async {
      const request = AiSuggestionRequest(
        prompt: 'test',
        homeType: 'family',
        listTitle: 'list',
        existingItems: [],
        language: 'fr',
      );

      expect(() => useCase(request), throwsA(isA<ValidationException>()));
    });
  });
}
