import '../../domain/entities/ai_response.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/ai_meal.dart';
import '../../domain/entities/ai_recipe_ingredient.dart';
import '../../domain/entities/ai_weekly_plan.dart';

/// Parses the raw JSON response from the Edge Function into typed [AiResponse].
class AiResponseModel {
  static AiResponse fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'error';

    switch (type) {
      case 'clarifying_questions':
        return AiClarifyingResponse(
          questions: _parseStringList(json['questions']),
          quickOptions: _parseStringList(json['quickOptions']),
        );

      case 'shopping_suggestions':
        final suggestions = _parseList(json['suggestions'] ?? json['sug'], _parseSuggestion);
        return AiShoppingSuggestionsResponse(suggestions: suggestions);

      case 'meal_suggestions':
        final mealsVal = json['meals'] ?? json['m'] ?? [];
        final sumVal = json['sum'] as String? ?? json['summary'] as String? ?? '';
        final meals = _parseList(mealsVal, _parseMeal);
        return AiMealSuggestionsResponse(
          summary: sumVal,
          meals: meals,
        );

      case 'recipe_ingredients':
        final mealVal = json['meal'] ?? json['m'];
        final ingredientsVal = json['ingredients'] ?? json['ing'] ?? [];
        final optionalIngredientsVal = json['optionalIngredients'] ?? json['opt_ing'] ?? [];
        final stepsVal = json['cookingStepsPreview'] ?? json['st'] ?? json['steps'] ?? [];

        return AiRecipeIngredientsResponse(
          meal: _parseMealInfo(mealVal as Map<String, dynamic>?),
          ingredients: _parseList(ingredientsVal, _parseIngredient),
          optionalIngredients: _parseList(optionalIngredientsVal, (j) => _parseIngredient(j, isRequired: false)),
          cookingStepsPreview: _parseStringList(stepsVal),
          shoppingSummary: _parseShoppingSummary(json['shoppingSummary'] as Map<String, dynamic>?),
        );

      case 'weekly_meal_plan':
        return AiWeeklyPlanResponse(
          plan: AiWeeklyPlan(
            summary: json['summary'] as String? ?? '',
            days: _parseList(json['days'], _parsePlanDay),
          ),
        );

      case 'pantry_based_meals':
        return AiPantryMealsResponse(
          summary: json['summary'] as String? ?? '',
          meals: _parseList(json['meals'], _parsePantryMeal),
        );

      case 'not_related':
        return AiNotRelatedResponse(
          message: json['message'] as String? ?? 'ai_error_not_related',
        );

      case 'error':
        return AiErrorResponse(
          message: json['message_ar'] as String? ?? json['error'] as String? ?? 'error_unexpected_generic',
        );

      default:
        return const AiErrorResponse(message: 'ai_error_parsing');
    }
  }

  /// Fallback parser that tries to detect the response type from structure
  /// when the 'type' field is missing (e.g. legacy responses).
  static AiResponse fromLegacyJson(Map<String, dynamic> json) {
    // If it has 'suggestions' array at root, treat as shopping_suggestions
    if (json.containsKey('suggestions') && json['suggestions'] is List) {
      final suggestions = _parseList(json['suggestions'], _parseSuggestion);
      return AiShoppingSuggestionsResponse(suggestions: suggestions);
    }
    // Otherwise try the typed parser
    return fromJson(json);
  }

  // --- Private Helpers ---

  static List<String> _parseStringList(dynamic val) {
    if (val is! List) return [];
    return val.whereType<String>().toList();
  }

  static List<T> _parseList<T>(dynamic val, T Function(Map<String, dynamic>) parser) {
    if (val is! List) return [];
    return val
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList();
  }

  static AiSuggestion _parseSuggestion(Map<String, dynamic> json) {
    final name = (json['name'] as String? ?? json['n'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      return const AiSuggestion(name: '—'); // Will be filtered
    }
    double qty = 1.0;
    final qtyVal = json['quantity'] ?? json['q'];
    if (qtyVal is num) {
      qty = qtyVal.toDouble();
      if (qty <= 0 || qty > 9999) qty = 1.0;
    }
    return AiSuggestion(
      name: name.length > 100 ? name.substring(0, 100) : name,
      quantity: qty,
      unit: _safeStr(json['unit'] ?? json['u']),
      category: _safeStr(json['category']),
      reason: _safeStr(json['reason']),
    );
  }

  static AiMeal _parseMeal(Map<String, dynamic> json) {
    final name = _safeStr(json['n']) ?? _safeStr(json['name']) ?? '';
    final description = _safeStr(json['d']) ?? _safeStr(json['description']) ?? '';
    final difficulty = _safeStr(json['df']) ?? _safeStr(json['difficulty']) ?? '';
    final time = _safeInt(json['t'], _safeInt(json['time'], _safeInt(json['estimatedTimeMinutes'], 30)));
    final servings = _safeInt(json['srv'], _safeInt(json['servings'], 4));
    final mealType = _safeStr(json['mealType']) ?? '';
    final cuisine = _safeStr(json['cuisine']) ?? '';
    final budgetLevel = _safeStr(json['budgetLevel']) ?? '';

    // Handle mainIngredients from 'ing' or 'mainIngredients'
    final ingList = json['ing'] ?? json['mainIngredients'];
    List<String> mainIngredients = [];
    if (ingList is List) {
      if (ingList.isNotEmpty && ingList.first is Map) {
        mainIngredients = ingList
            .whereType<Map<String, dynamic>>()
            .map((m) => (_safeStr(m['n']) ?? _safeStr(m['name']) ?? ''))
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        mainIngredients = _parseStringList(ingList);
      }
    }

    final whyThisMeal = _safeStr(json['whyThisMeal']) ?? '';
    final tags = _parseStringList(json['tags']);

    return AiMeal(
      name: name,
      description: description,
      difficulty: difficulty,
      estimatedTimeMinutes: time,
      servings: servings,
      mealType: mealType,
      cuisine: cuisine,
      budgetLevel: budgetLevel,
      mainIngredients: mainIngredients,
      whyThisMeal: whyThisMeal,
      tags: tags,
    );
  }

  static AiPantryMeal _parsePantryMeal(Map<String, dynamic> json) {
    return AiPantryMeal(
      name: _safeStr(json['n']) ?? _safeStr(json['name']) ?? '',
      description: _safeStr(json['d']) ?? _safeStr(json['description']) ?? '',
      difficulty: _safeStr(json['df']) ?? _safeStr(json['difficulty']) ?? '',
      estimatedTimeMinutes: _safeInt(json['t'], _safeInt(json['time'], _safeInt(json['estimatedTimeMinutes'], 30))),
      servings: _safeInt(json['srv'], _safeInt(json['servings'], 4)),
      cuisine: _safeStr(json['cuisine']) ?? '',
      availableIngredients: _parseStringList(json['availableIngredients'] ?? json['av_ing']),
      missingIngredients: _parseStringList(json['missingIngredients'] ?? json['mis_ing']),
      whyThisMeal: _safeStr(json['whyThisMeal']) ?? '',
      tags: _parseStringList(json['tags']),
    );
  }

  static AiMealInfo _parseMealInfo(Map<String, dynamic>? json) {
    if (json == null) {
      return const AiMealInfo(name: '');
    }
    return AiMealInfo(
      name: _safeStr(json['n']) ?? _safeStr(json['name']) ?? '',
      description: _safeStr(json['d']) ?? _safeStr(json['description']) ?? '',
      servings: _safeInt(json['srv'], _safeInt(json['servings'], 4)),
      estimatedTimeMinutes: _safeInt(json['t'], _safeInt(json['time'], _safeInt(json['estimatedTimeMinutes'], 30))),
      difficulty: _safeStr(json['df']) ?? _safeStr(json['difficulty']) ?? '',
      cuisine: _safeStr(json['cuisine']) ?? '',
    );
  }

  static AiRecipeIngredient _parseIngredient(Map<String, dynamic> json, {bool isRequired = true}) {
    double qty = 1.0;
    final qtyVal = json['q'] ?? json['quantity'];
    if (qtyVal is num) {
      qty = qtyVal.toDouble();
      if (qty <= 0 || qty > 9999) qty = 1.0;
    }

    final name = _safeStr(json['n']) ?? _safeStr(json['name']) ?? '';
    final foodKey = _safeStr(json['k']) ?? _safeStr(json['food_key']) ?? _safeStr(json['foodKey']);
    final unit = _safeStr(json['u']) ?? _safeStr(json['unit']);
    final category = _safeStr(json['category']);
    final requiredVal = json['r'] ?? json['required'];
    final isReq = requiredVal is bool ? requiredVal : isRequired;
    
    final status = IngredientStatus.fromApiValue(json['status'] as String?);
    final reason = _safeStr(json['reason']);
    final note = _safeStr(json['note']);

    return AiRecipeIngredient(
      name: name,
      foodKey: foodKey,
      quantity: qty,
      unit: unit,
      category: category,
      required: isReq,
      status: status,
      reason: reason,
      note: note,
    );
  }

  static ShoppingSummary _parseShoppingSummary(Map<String, dynamic>? json) {
    if (json == null) return const ShoppingSummary();
    return ShoppingSummary(
      availableCount: _safeInt(json['availableCount'], 0),
      missingCount: _safeInt(json['missingCount'], 0),
      alreadyInListCount: _safeInt(json['alreadyInListCount'], 0),
    );
  }

  static AiPlanDay _parsePlanDay(Map<String, dynamic> json) {
    final meals = _parseList(json['meals'], _parseDayMeal);
    return AiPlanDay(
      day: json['day'] as String? ?? '',
      meals: meals,
    );
  }

  static AiDayMeal _parseDayMeal(Map<String, dynamic> json) {
    return AiDayMeal(
      name: _safeStr(json['name']) ?? '',
      mealType: _safeStr(json['mealType']) ?? '',
      description: _safeStr(json['description']) ?? '',
      mainIngredients: _parseStringList(json['mainIngredients']),
      estimatedTimeMinutes: _safeInt(json['estimatedTimeMinutes'], 30),
    );
  }

  static String? _safeStr(dynamic val) {
    if (val is! String) return null;
    final trimmed = val.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _safeInt(dynamic val, int defaultVal) {
    if (val is int) return val > 0 ? val : defaultVal;
    if (val is double) return val > 0 ? val.toInt() : defaultVal;
    return defaultVal;
  }
}
