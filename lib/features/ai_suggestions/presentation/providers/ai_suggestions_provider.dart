import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/ai_suggestion_request.dart';
import '../../domain/usecases/get_ai_suggestions.dart';
import '../../data/datasources/ai_suggestion_remote_data_source.dart';
import '../../data/repositories/ai_suggestion_repository_impl.dart';

// --- State ---
sealed class AiSuggestionsState {
  const AiSuggestionsState();
}

class AiSuggestionsIdle extends AiSuggestionsState {
  const AiSuggestionsIdle();
}

class AiSuggestionsLoading extends AiSuggestionsState {
  const AiSuggestionsLoading();
}

class AiSuggestionsSuccess extends AiSuggestionsState {
  final List<AiSuggestion> suggestions;
  final Set<int> selectedIndices;

  const AiSuggestionsSuccess(this.suggestions, this.selectedIndices);

  AiSuggestionsSuccess copyWith({
    List<AiSuggestion>? suggestions,
    Set<int>? selectedIndices,
  }) {
    return AiSuggestionsSuccess(
      suggestions ?? this.suggestions,
      selectedIndices ?? this.selectedIndices,
    );
  }
}

class AiSuggestionsError extends AiSuggestionsState {
  final String message;
  const AiSuggestionsError(this.message);
}

class AiSuggestionsAdding extends AiSuggestionsState {
  final List<AiSuggestion> suggestions;
  final Set<int> selectedIndices;

  const AiSuggestionsAdding(this.suggestions, this.selectedIndices);
}

// --- Provider Setup ---
final aiSuggestionRemoteDataSourceProvider = Provider<AiSuggestionRemoteDataSource>((ref) {
  return AiSuggestionRemoteDataSource(supabaseClient: SupabaseService.client);
});

final aiSuggestionRepositoryProvider = Provider<AiSuggestionRepositoryImpl>((ref) {
  final remoteDataSource = ref.watch(aiSuggestionRemoteDataSourceProvider);
  return AiSuggestionRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getAiSuggestionsUseCaseProvider = Provider<GetAiSuggestions>((ref) {
  final repository = ref.watch(aiSuggestionRepositoryProvider);
  return GetAiSuggestions(repository);
});

final aiSuggestionsProvider = StateNotifierProvider<AiSuggestionsNotifier, AiSuggestionsState>((ref) {
  final getAiSuggestions = ref.watch(getAiSuggestionsUseCaseProvider);
  return AiSuggestionsNotifier(getAiSuggestions);
});

// --- State Notifier ---
class AiSuggestionsNotifier extends StateNotifier<AiSuggestionsState> {
  final GetAiSuggestions _getAiSuggestions;

  AiSuggestionsNotifier(this._getAiSuggestions) : super(const AiSuggestionsIdle());

  void fetchSuggestions(AiSuggestionRequest request) async {
    state = const AiSuggestionsLoading();
    try {
      final suggestions = await _getAiSuggestions(request);
      state = AiSuggestionsSuccess(suggestions, <int>{});
    } catch (e) {
      state = AiSuggestionsError(e.toString());
    }
  }

  void toggleSelection(int index) {
    final currentState = state;
    if (currentState is AiSuggestionsSuccess) {
      final newSelection = Set<int>.from(currentState.selectedIndices);
      if (newSelection.contains(index)) {
        newSelection.remove(index);
      } else {
        newSelection.add(index);
      }
      state = currentState.copyWith(selectedIndices: newSelection);
    }
  }

  void selectAll() {
    final currentState = state;
    if (currentState is AiSuggestionsSuccess) {
      final allIndices = Set<int>.from(
        List.generate(currentState.suggestions.length, (index) => index)
      );
      state = currentState.copyWith(selectedIndices: allIndices);
    }
  }

  void deselectAll() {
    final currentState = state;
    if (currentState is AiSuggestionsSuccess) {
      state = currentState.copyWith(selectedIndices: <int>{});
    }
  }

  List<AiSuggestion> getSelectedSuggestions() {
    final currentState = state;
    if (currentState is AiSuggestionsSuccess) {
      return currentState.selectedIndices
          .map((i) => currentState.suggestions[i])
          .toList();
    } else if (currentState is AiSuggestionsAdding) {
      return currentState.selectedIndices
          .map((i) => currentState.suggestions[i])
          .toList();
    }
    return [];
  }

  void setAddingState() {
    final currentState = state;
    if (currentState is AiSuggestionsSuccess) {
      state = AiSuggestionsAdding(currentState.suggestions, currentState.selectedIndices);
    }
  }

  void reset() {
    state = const AiSuggestionsIdle();
  }
}
