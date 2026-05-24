class AiSuggestionRequest {
  final String prompt;
  final String homeType;
  final String listTitle;
  final List<String> existingItems;
  final String language;

  const AiSuggestionRequest({
    required this.prompt,
    required this.homeType,
    required this.listTitle,
    required this.existingItems,
    required this.language,
  });

  List<String> validate() {
    final errors = <String>[];

    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      errors.add('Prompt cannot be empty.');
    } else if (trimmedPrompt.length > 500) {
      errors.add('Prompt must be 500 characters or less.');
    }

    if (homeType.trim().isEmpty) {
      errors.add('Home type cannot be empty.');
    }

    if (listTitle.trim().isEmpty) {
      errors.add('List title cannot be empty.');
    }

    if (existingItems.length > 100) {
      errors.add('Existing items cannot exceed 100 entries.');
    }

    if (language != 'ar' && language != 'en') {
      errors.add('Language must be either "ar" or "en".');
    }

    return errors;
  }
}
