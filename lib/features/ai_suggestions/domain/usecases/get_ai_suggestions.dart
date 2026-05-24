import '../../../../core/error/exceptions.dart';
import '../entities/ai_suggestion.dart';
import '../entities/ai_suggestion_request.dart';
import '../repositories/ai_suggestion_repository.dart';

class GetAiSuggestions {
  final AiSuggestionRepository repository;

  GetAiSuggestions(this.repository);

  Future<List<AiSuggestion>> call(AiSuggestionRequest request) async {
    final validationErrors = request.validate();
    if (validationErrors.isNotEmpty) {
      throw ValidationException(validationErrors.join(' '));
    }

    return await repository.getSuggestions(request);
  }
}
