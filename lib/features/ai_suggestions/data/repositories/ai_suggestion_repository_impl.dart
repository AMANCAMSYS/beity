import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/ai_suggestion_request.dart';
import '../../domain/repositories/ai_suggestion_repository.dart';
import '../datasources/ai_suggestion_remote_data_source.dart';
import '../models/ai_suggestion_request_model.dart';

class AiSuggestionRepositoryImpl implements AiSuggestionRepository {
  final AiSuggestionRemoteDataSource remoteDataSource;

  AiSuggestionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AiSuggestion>> getSuggestions(AiSuggestionRequest request) async {
    try {
      final requestModel = AiSuggestionRequestModel.fromEntity(request);
      final models = await remoteDataSource.fetchSuggestions(requestModel);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Re-throw known exceptions
      if (e is AiValidationException || e is AiServiceException) {
        rethrow;
      }
      // Wrap unexpected exceptions
      throw DatabaseException(message: 'Failed to get AI suggestions: ${e.toString()}');
    }
  }
}
