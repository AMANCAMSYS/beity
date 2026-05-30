import '../../../../core/errors/app_exception.dart';
import '../entities/ai_suggestion.dart';
import '../entities/ai_suggestion_request.dart';
import '../repositories/ai_suggestion_repository.dart';

class GetAiSuggestions {
  final AiSuggestionRepository repository;

  GetAiSuggestions(this.repository);

  Future<List<AiSuggestion>> call(AiSuggestionRequest request) async {
    final validationErrors = request.validate();
    if (validationErrors.isNotEmpty) {
      throw ValidationException(message: validationErrors.join(' '));
    }

    return repository.getSuggestions(request);
  }
}
