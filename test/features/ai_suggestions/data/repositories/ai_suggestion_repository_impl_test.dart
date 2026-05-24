import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/ai_suggestions/data/datasources/ai_suggestion_remote_data_source.dart';
import 'package:beity/features/ai_suggestions/data/models/ai_suggestion_model.dart';
import 'package:beity/features/ai_suggestions/data/models/ai_suggestion_request_model.dart';
import 'package:beity/features/ai_suggestions/data/repositories/ai_suggestion_repository_impl.dart';
import 'package:beity/features/ai_suggestions/domain/entities/ai_suggestion_request.dart';
import 'package:beity/core/error/exceptions.dart';

class MockAiSuggestionRemoteDataSource extends Mock implements AiSuggestionRemoteDataSource {}

void main() {
  late MockAiSuggestionRemoteDataSource mockRemoteDataSource;
  late AiSuggestionRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAiSuggestionRemoteDataSource();
    repository = AiSuggestionRepositoryImpl(remoteDataSource: mockRemoteDataSource);
    
    registerFallbackValue(const AiSuggestionRequestModel(
      prompt: '',
      homeType: '',
      listTitle: '',
      existingItems: [],
      language: 'en',
    ));
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
      when(() => mockRemoteDataSource.fetchSuggestions(any()))
          .thenAnswer((_) async => tModels);

      final result = await repository.getSuggestions(tRequest);

      expect(result.length, 2);
      expect(result[0].name, 'Milk');
      expect(result[1].name, 'Eggs');
      verify(() => mockRemoteDataSource.fetchSuggestions(any())).called(1);
    });

    test('rethrows AiValidationException', () async {
      when(() => mockRemoteDataSource.fetchSuggestions(any()))
          .thenThrow(const AiValidationException('Invalid input'));

      expect(() => repository.getSuggestions(tRequest), throwsA(isA<AiValidationException>()));
    });

    test('rethrows AiServiceException', () async {
      when(() => mockRemoteDataSource.fetchSuggestions(any()))
          .thenThrow(const AiServiceException('API Error'));

      expect(() => repository.getSuggestions(tRequest), throwsA(isA<AiServiceException>()));
    });

    test('wraps unexpected exceptions into ServerException', () async {
      when(() => mockRemoteDataSource.fetchSuggestions(any()))
          .thenThrow(Exception('Unexpected error'));

      expect(() => repository.getSuggestions(tRequest), throwsA(isA<ServerException>()));
    });
  });
}
