import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/ai_suggestions/domain/entities/ai_suggestion.dart';
import 'package:beity/features/ai_suggestions/domain/entities/ai_suggestion_request.dart';
import 'package:beity/features/ai_suggestions/domain/usecases/get_ai_suggestions.dart';
import 'package:beity/features/ai_suggestions/presentation/providers/ai_suggestions_provider.dart';

class MockGetAiSuggestions extends Mock implements GetAiSuggestions {}

void main() {
  late MockGetAiSuggestions mockGetAiSuggestions;
  late AiSuggestionsNotifier notifier;

  setUp(() {
    mockGetAiSuggestions = MockGetAiSuggestions();
    notifier = AiSuggestionsNotifier(mockGetAiSuggestions);
    
    registerFallbackValue(const AiSuggestionRequest(
      prompt: '',
      homeType: '',
      listTitle: '',
      existingItems: [],
      language: 'en',
    ));
  });

  const tRequest = AiSuggestionRequest(
    prompt: 'test',
    homeType: 'family',
    listTitle: 'list',
    existingItems: [],
    language: 'en',
  );

  const tSuggestions = [
    AiSuggestion(name: 'Milk'),
    AiSuggestion(name: 'Eggs'),
  ];

  group('AiSuggestionsNotifier', () {
    test('initial state is idle', () {
      expect(notifier.state, isA<AiSuggestionsIdle>());
    });

    test('fetchSuggestions updates state to loading then success', () async {
      when(() => mockGetAiSuggestions(any()))
          .thenAnswer((_) async => tSuggestions);

      notifier.fetchSuggestions(tRequest);

      // Verify loading state (since it's async)
      expect(notifier.state, isA<AiSuggestionsLoading>());

      // Wait for debouncer and async action
      await Future.delayed(const Duration(milliseconds: 500));

      expect(notifier.state, isA<AiSuggestionsSuccess>());
      final successState = notifier.state as AiSuggestionsSuccess;
      expect(successState.suggestions, tSuggestions);
      expect(successState.selectedIndices, isEmpty);
    });

    test('fetchSuggestions updates state to error on failure', () async {
      when(() => mockGetAiSuggestions(any()))
          .thenThrow(Exception('Service Error'));

      notifier.fetchSuggestions(tRequest);

      await Future.delayed(const Duration(milliseconds: 500));

      expect(notifier.state, isA<AiSuggestionsError>());
      final errorState = notifier.state as AiSuggestionsError;
      expect(errorState.message, contains('Service Error'));
    });

    test('toggleSelection works correctly', () async {
      when(() => mockGetAiSuggestions(any()))
          .thenAnswer((_) async => tSuggestions);

      notifier.fetchSuggestions(tRequest);
      await Future.delayed(const Duration(milliseconds: 500));

      notifier.toggleSelection(0);
      expect((notifier.state as AiSuggestionsSuccess).selectedIndices, {0});

      notifier.toggleSelection(0);
      expect((notifier.state as AiSuggestionsSuccess).selectedIndices, isEmpty);

      notifier.toggleSelection(1);
      expect((notifier.state as AiSuggestionsSuccess).selectedIndices, {1});
    });

    test('selectAll and deselectAll work correctly', () async {
      when(() => mockGetAiSuggestions(any()))
          .thenAnswer((_) async => tSuggestions);

      notifier.fetchSuggestions(tRequest);
      await Future.delayed(const Duration(milliseconds: 500));

      notifier.selectAll();
      expect((notifier.state as AiSuggestionsSuccess).selectedIndices, {0, 1});

      notifier.deselectAll();
      expect((notifier.state as AiSuggestionsSuccess).selectedIndices, isEmpty);
    });

    test('reset clears state back to idle', () async {
      when(() => mockGetAiSuggestions(any()))
          .thenAnswer((_) async => tSuggestions);

      notifier.fetchSuggestions(tRequest);
      await Future.delayed(const Duration(milliseconds: 500));

      notifier.reset();
      expect(notifier.state, isA<AiSuggestionsIdle>());
    });
  });
}
