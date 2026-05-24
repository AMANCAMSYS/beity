import '../entities/ai_suggestion.dart';
import '../entities/ai_suggestion_request.dart';

abstract class AiSuggestionRepository {
  Future<List<AiSuggestion>> getSuggestions(AiSuggestionRequest request);
}
