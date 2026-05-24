import 'ai_mode.dart';

class AiAssistantRequest {
  final AiMode mode;
  final String userPrompt;
  final String language;

  // Optional context
  final String? homeType;
  final String? listTitle;
  final List<String> existingShoppingItems;
  final List<String> inventoryItems;
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

  const AiAssistantRequest({
    required this.mode,
    required this.userPrompt,
    required this.language,
    this.homeType,
    this.listTitle,
    this.existingShoppingItems = const [],
    this.inventoryItems = const [],
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
  });

  List<String> validate() {
    final errors = <String>[];

    final trimmedPrompt = userPrompt.trim();
    if (trimmedPrompt.isEmpty) {
      errors.add('اكتب ما تريد اقتراحه أولًا');
    } else if (trimmedPrompt.length > 500) {
      errors.add('النص طويل جدًا (الحد الأقصى 500 حرف)');
    }

    if (language != 'ar' && language != 'en') {
      errors.add('اللغة غير مدعومة');
    }

    if (existingShoppingItems.length > 100) {
      errors.add('عناصر القائمة الحالية تتجاوز الحد (100)');
    }

    if (inventoryItems.length > 100) {
      errors.add('عناصر المخزون تتجاوز الحد (100)');
    }

    return errors;
  }
}
