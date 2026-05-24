/// A single meal suggestion from the AI.
class AiMeal {
  final String name;
  final String description;
  final String difficulty;
  final int estimatedTimeMinutes;
  final int servings;
  final String mealType;
  final String cuisine;
  final String budgetLevel;
  final List<String> mainIngredients;
  final String whyThisMeal;
  final List<String> tags;

  const AiMeal({
    required this.name,
    this.description = '',
    this.difficulty = '',
    this.estimatedTimeMinutes = 30,
    this.servings = 4,
    this.mealType = '',
    this.cuisine = '',
    this.budgetLevel = '',
    this.mainIngredients = const [],
    this.whyThisMeal = '',
    this.tags = const [],
  });
}

/// A meal in a pantry-based response, with available/missing ingredient breakdown.
class AiPantryMeal {
  final String name;
  final String description;
  final String difficulty;
  final int estimatedTimeMinutes;
  final int servings;
  final String cuisine;
  final List<String> availableIngredients;
  final List<String> missingIngredients;
  final String whyThisMeal;
  final List<String> tags;

  const AiPantryMeal({
    required this.name,
    this.description = '',
    this.difficulty = '',
    this.estimatedTimeMinutes = 30,
    this.servings = 4,
    this.cuisine = '',
    this.availableIngredients = const [],
    this.missingIngredients = const [],
    this.whyThisMeal = '',
    this.tags = const [],
  });
}
