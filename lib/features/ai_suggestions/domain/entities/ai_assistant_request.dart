import 'ai_mode.dart';

class AiAssistantRequest {
  final AiMode mode;
  final String userPrompt;
  final String language;

  // Optional context
  final String? homeId;
  final String? listId;
  final String? homeType;
  final String? listTitle;
  final List<String> existingShoppingItems;
  final List<String> inventoryItems;
  final Map<String, String> userTerms;
  final int? servings;
  final String? preferredCuisine;
  final String? dietaryPreference;
  final String? budgetLevel;
  final int? maxPreparationTimeMinutes;
  final List<String> availableVegetables;
  final List<String> availableSpices;
  final List<String> availableProteins;
  final List<String> availableCarbs;
  final List<String> excludedIngredients;
  final String? occasion;
  final String? mealType;
  final String? cookingSkillLevel;
  final String? country;
  final String? dialect;

  const AiAssistantRequest({
    required this.mode,
    required this.userPrompt,
    required this.language,
    this.homeId,
    this.listId,
    this.homeType,
    this.listTitle,
    this.existingShoppingItems = const [],
    this.inventoryItems = const [],
    this.userTerms = const {},
    this.servings,
    this.preferredCuisine,
    this.dietaryPreference,
    this.budgetLevel,
    this.maxPreparationTimeMinutes,
    this.availableVegetables = const [],
    this.availableSpices = const [],
    this.availableProteins = const [],
    this.availableCarbs = const [],
    this.excludedIngredients = const [],
    this.occasion,
    this.mealType,
    this.cookingSkillLevel,
    this.country,
    this.dialect,
  });

  List<String> validate() {
    final errors = <String>[];

    final trimmedPrompt = userPrompt.trim();
    if (trimmedPrompt.isEmpty) {
      errors.add('ai_error_prompt_empty');
    } else if (trimmedPrompt.length > 500) {
      errors.add('ai_error_prompt_too_long');
    }

    if (language != 'ar' && language != 'en' && language != 'tr') {
      errors.add('ai_error_lang_unsupported');
    }

    if (existingShoppingItems.length > 100) {
      errors.add('ai_error_list_items_limit');
    }

    if (inventoryItems.length > 100) {
      errors.add('ai_error_inventory_items_limit');
    }

    return errors;
  }
}
