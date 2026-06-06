import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/ai_suggestion_request.dart';
import '../../domain/repositories/ai_suggestion_repository.dart';
import '../datasources/ai_suggestion_remote_data_source.dart';
import '../models/ai_suggestion_model.dart';
import '../models/ai_suggestion_request_model.dart';

class AiSuggestionRepositoryImpl implements AiSuggestionRepository {
  final AiSuggestionRemoteDataSource remoteDataSource;

  AiSuggestionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AiSuggestion>> getSuggestions(AiSuggestionRequest request) async {
    try {
      final requestModel = AiSuggestionRequestModel.fromEntity(request);
      final models = await remoteDataSource.fetchSuggestions(requestModel);
      return _qualityGateSuggestions(models, request.existingItems);
    } catch (e) {
      // Re-throw known exceptions
      if (e is AiValidationException || e is AiServiceException) {
        rethrow;
      }
      // Wrap unexpected exceptions
      throw const DatabaseException(message: 'unexpected_error_retry');
    }
  }

  List<AiSuggestion> _qualityGateSuggestions(
    List<AiSuggestionModel> models,
    List<String> existingItems,
  ) {
    final seenNames = existingItems
        .map(_dedupeKey)
        .where((key) => key.isNotEmpty)
        .toSet();
    final suggestions = <AiSuggestion>[];

    for (final model in models) {
      final entity = model.toEntity();
      final name = _sanitizeName(entity.name);
      final key = _dedupeKey(name);
      if (key.isEmpty || seenNames.contains(key)) continue;

      seenNames.add(key);
      suggestions.add(
        AiSuggestion(
          name: name,
          quantity: entity.quantity,
          unit: _sanitizeOptionalText(entity.unit, maxLength: 24),
          category: _sanitizeOptionalText(entity.category, maxLength: 40),
          reason: _sanitizeOptionalText(entity.reason, maxLength: 120),
          status: entity.status,
          displayName: _sanitizeOptionalText(
            entity.displayName,
            maxLength: 100,
          ),
          sourceListName: _sanitizeOptionalText(
            entity.sourceListName,
            maxLength: 80,
          ),
        ),
      );
    }

    return suggestions.take(20).toList();
  }

  String _sanitizeName(String value) {
    final compact = _redactSensitiveText(
      value,
    ).trim().replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length <= 100) return compact;
    return compact.substring(0, 100).trim();
  }

  String? _sanitizeOptionalText(String? value, {required int maxLength}) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final sanitized = _redactSensitiveText(
      text,
    ).trim().replaceAll(RegExp(r'\s+'), ' ');
    if (sanitized.isEmpty) return null;
    if (sanitized.length <= maxLength) return sanitized;
    return sanitized.substring(0, maxLength).trim();
  }

  String _dedupeKey(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _redactSensitiveText(String value) {
    return value
        .replaceAll(
          RegExp(
            r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
            caseSensitive: false,
          ),
          '[email]',
        )
        .replaceAll(
          RegExp(
            r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
            caseSensitive: false,
          ),
          '[id]',
        )
        .replaceAll(
          RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
          '[token]',
        )
        .replaceAll(RegExp(r'\b[A-Za-z0-9_-]{32,}\b'), '[secret]');
  }
}
