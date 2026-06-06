import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/ai_suggestions/data/datasources/ai_suggestion_remote_data_source.dart';
import 'package:sawa/features/ai_suggestions/data/models/ai_suggestion_model.dart';
import 'package:sawa/features/ai_suggestions/data/models/ai_suggestion_request_model.dart';
import 'package:sawa/features/ai_suggestions/data/repositories/ai_suggestion_repository_impl.dart';
import 'package:sawa/features/ai_suggestions/domain/entities/ai_suggestion_request.dart';
import 'package:sawa/core/errors/app_exception.dart';

class MockAiSuggestionRemoteDataSource extends Mock
    implements AiSuggestionRemoteDataSource {}

void main() {
  late MockAiSuggestionRemoteDataSource mockRemoteDataSource;
  late AiSuggestionRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAiSuggestionRemoteDataSource();
    repository = AiSuggestionRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );

    registerFallbackValue(
      const AiSuggestionRequestModel(
        prompt: '',
        homeType: '',
        listTitle: '',
        existingItems: [],
        language: 'en',
      ),
    );
  });

  const tRequest = AiSuggestionRequest(
    prompt: 'test prompt',
    homeType: 'family',
    listTitle: 'test list',
    existingItems: ['item1'],
    language: 'en',
  );

  final tModels = [
    const AiSuggestionModel(name: 'Milk', quantity: 1.0),
    const AiSuggestionModel(name: 'Eggs', quantity: 12.0),
  ];

  group('AiSuggestionRepositoryImpl', () {
    test('returns parsed suggestions on success', () async {
      when(
        () => mockRemoteDataSource.fetchSuggestions(any()),
      ).thenAnswer((_) async => tModels);

      final result = await repository.getSuggestions(tRequest);

      expect(result.length, 2);
      expect(result[0].name, 'Milk');
      expect(result[1].name, 'Eggs');
      verify(() => mockRemoteDataSource.fetchSuggestions(any())).called(1);
    });

    test('filters duplicates and redacts sensitive suggestion text', () async {
      final models = [
        const AiSuggestionModel(name: ' item1 '),
        const AiSuggestionModel(name: 'Milk', reason: 'Buy for user@test.com'),
        const AiSuggestionModel(
          name: ' milk ',
          category: 'secret abcdefghijklmnopqrstuvwxyzABCDEF',
        ),
        const AiSuggestionModel(
          name: 'Eggs',
          unit: 'pcs',
          reason:
              'trace 123e4567-e89b-12d3-a456-426614174000 and eyJabc.def.ghi',
        ),
      ];
      when(
        () => mockRemoteDataSource.fetchSuggestions(any()),
      ).thenAnswer((_) async => models);

      final result = await repository.getSuggestions(tRequest);

      expect(result.map((item) => item.name), ['Milk', 'Eggs']);
      expect(result.first.reason, 'Buy for [email]');
      expect(result.last.reason, contains('[id]'));
      expect(result.last.reason, contains('[token]'));
    });

    test('rethrows AiValidationException', () async {
      when(
        () => mockRemoteDataSource.fetchSuggestions(any()),
      ).thenThrow(const AiValidationException('Invalid input'));

      expect(
        () => repository.getSuggestions(tRequest),
        throwsA(isA<AiValidationException>()),
      );
    });

    test('rethrows AiServiceException', () async {
      when(
        () => mockRemoteDataSource.fetchSuggestions(any()),
      ).thenThrow(const AiServiceException('API Error'));

      expect(
        () => repository.getSuggestions(tRequest),
        throwsA(isA<AiServiceException>()),
      );
    });

    test('wraps unexpected exceptions into ServerException', () async {
      when(
        () => mockRemoteDataSource.fetchSuggestions(any()),
      ).thenThrow(Exception('Unexpected error'));

      expect(
        () => repository.getSuggestions(tRequest),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
