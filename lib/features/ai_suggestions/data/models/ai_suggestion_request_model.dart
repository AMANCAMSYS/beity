import '../../domain/entities/ai_suggestion_request.dart';

class AiSuggestionRequestModel {
  final String prompt;
  final String homeType;
  final String listTitle;
  final List<String> existingItems;
  final String language;

  const AiSuggestionRequestModel({
    required this.prompt,
    required this.homeType,
    required this.listTitle,
    required this.existingItems,
    required this.language,
  });

  factory AiSuggestionRequestModel.fromEntity(AiSuggestionRequest entity) {
    return AiSuggestionRequestModel(
      prompt: entity.prompt.trim(),
      homeType: entity.homeType.trim(),
      listTitle: entity.listTitle.trim(),
      // Ensure only item name strings are passed, up to 100 items.
      existingItems: entity.existingItems
          .take(100)
          .map((e) => e.trim())
          .toList(),
      language: entity.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'homeType': homeType,
      'listTitle': listTitle,
      'existingItems': existingItems,
      'language': language,
    };
  }
}
