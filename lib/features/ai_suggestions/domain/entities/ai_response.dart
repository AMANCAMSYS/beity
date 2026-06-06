import 'ai_suggestion.dart';
import 'ai_meal.dart';
import 'ai_recipe_ingredient.dart';
import 'ai_weekly_plan.dart';

/// Sealed class representing all possible AI response types.
sealed class AiResponse {
  const AiResponse();
}

/// Clarifying questions returned when the user prompt is vague.
class AiClarifyingResponse extends AiResponse {
  final List<String> questions;
  final List<String> quickOptions;

  const AiClarifyingResponse({
    this.questions = const [],
    this.quickOptions = const [],
  });
}

/// Shopping item suggestions (legacy + new mode).
class AiShoppingSuggestionsResponse extends AiResponse {
  final List<AiSuggestion> suggestions;

  const AiShoppingSuggestionsResponse({this.suggestions = const []});
}

/// Multiple meal suggestions.
class AiMealSuggestionsResponse extends AiResponse {
  final String summary;
  final List<AiMeal> meals;

  const AiMealSuggestionsResponse({this.summary = '', this.meals = const []});
}

/// Full recipe ingredients for a specific meal.
class AiRecipeIngredientsResponse extends AiResponse {
  final AiMealInfo meal;
  final List<AiRecipeIngredient> ingredients;
  final List<AiRecipeIngredient> optionalIngredients;
  final List<String> cookingStepsPreview;
  final ShoppingSummary shoppingSummary;

  const AiRecipeIngredientsResponse({
    required this.meal,
    this.ingredients = const [],
    this.optionalIngredients = const [],
    this.cookingStepsPreview = const [],
    this.shoppingSummary = const ShoppingSummary(),
  });
}

/// Weekly meal plan.
class AiWeeklyPlanResponse extends AiResponse {
  final AiWeeklyPlan plan;

  const AiWeeklyPlanResponse({required this.plan});
}

/// Pantry-based meal suggestions.
class AiPantryMealsResponse extends AiResponse {
  final String summary;
  final List<AiPantryMeal> meals;

  const AiPantryMealsResponse({this.summary = '', this.meals = const []});
}

/// Response when the user asks something outside the app's scope.
class AiNotRelatedResponse extends AiResponse {
  final String message;

  const AiNotRelatedResponse({this.message = 'هذا الطلب خارج تخصصي.'});
}

/// Error response.
class AiErrorResponse extends AiResponse {
  final String message;

  const AiErrorResponse({this.message = 'حدث خطأ غير متوقع'});
}
