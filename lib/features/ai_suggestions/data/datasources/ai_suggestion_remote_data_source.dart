import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/entities/ai_assistant_request.dart';
import '../models/ai_assistant_request_model.dart';
import '../models/ai_response_model.dart';
import '../models/ai_suggestion_model.dart';
import '../models/ai_suggestion_request_model.dart';

class AiValidationException implements Exception {
  final String message;
  const AiValidationException(this.message);

  @override
  String toString() => 'AiValidationException: $message';
}

class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);

  @override
  String toString() => 'AiServiceException: $message';
}

class AiSuggestionRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AiSuggestionRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// New method: Fetch AI response for the advanced assistant.
  Future<AiResponse> fetchAssistantResponse(AiAssistantRequest request) async {
    try {
      final requestModel = AiAssistantRequestModel(request);
      final response = await _supabaseClient.functions.invoke(
        'generate-shopping-suggestions',
        body: requestModel.toJson(),
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // Try typed response first, then legacy fallback
          if (data.containsKey('type')) {
            return AiResponseModel.fromJson(data);
          } else {
            return AiResponseModel.fromLegacyJson(data);
          }
        } else {
          throw const AiServiceException('تعذر قراءة الاقتراحات، حاول مرة أخرى');
        }
      } else if (response.status == 400) {
        final errorMsg = _extractErrorMessage(response.data) ?? 'طلب غير صالح';
        throw AiValidationException(errorMsg);
      } else {
        final errorMsg = _extractErrorMessage(response.data) ?? 'تعذر إنشاء الاقتراحات، حاول مرة أخرى';
        throw AiServiceException(errorMsg);
      }
    } on FunctionException catch (e) {
      if (e.status == 400) {
        final errorMsg = _extractErrorMessage(e.details) ?? 'طلب غير صالح';
        throw AiValidationException(errorMsg);
      }
      final errorMsg = _extractErrorMessage(e.details) ?? e.reasonPhrase ?? 'الخدمة غير متاحة';
      throw AiServiceException(errorMsg);
    } catch (e) {
      if (e is AiValidationException || e is AiServiceException) {
        rethrow;
      }
      throw AiServiceException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  /// Legacy method: Fetch suggestions only (for backward compatibility).
  Future<List<AiSuggestionModel>> fetchSuggestions(AiSuggestionRequestModel request) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'generate-shopping-suggestions',
        body: request.toJson(),
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('suggestions')) {
          final suggestionsList = data['suggestions'] as List<dynamic>;
          // Cap at 20 items
          final cappedList = suggestionsList.take(20);
          return cappedList
              .map((json) => AiSuggestionModel.fromJson(json as Map<String, dynamic>))
              .where((model) => model.name.isNotEmpty) // Extra safety check
              .toList();
        } else {
          throw const AiServiceException('Invalid response format: missing suggestions array.');
        }
      } else if (response.status == 400) {
        final errorMsg = _extractErrorMessage(response.data) ?? 'Invalid request.';
        throw AiValidationException(errorMsg);
      } else {
        final errorMsg = _extractErrorMessage(response.data) ?? 'Failed to generate suggestions.';
        throw AiServiceException(errorMsg);
      }
    } on FunctionException catch (e) {
      if (e.status == 400) {
        final errorMsg = _extractErrorMessage(e.details) ?? 'Invalid request.';
        throw AiValidationException(errorMsg);
      }
      final errorMsg = _extractErrorMessage(e.details) ?? e.reasonPhrase ?? 'Service unavailable.';
      throw AiServiceException(errorMsg);
    } catch (e) {
      if (e is AiValidationException || e is AiServiceException) {
        rethrow;
      }
      throw AiServiceException('An unexpected error occurred: ${e.toString()}');
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Prefer Arabic message
      if (data.containsKey('message_ar')) {
        return data['message_ar']?.toString();
      }
      if (data.containsKey('error')) {
        return data['error']?.toString();
      }
    }
    return null;
  }
}
