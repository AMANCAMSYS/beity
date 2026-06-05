import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

const _translationKeys = {
  'shopping_suggestions': 'mode_shopping_suggestions',
  'what_to_cook': 'mode_what_to_cook',
  'recipe_ingredients': 'mode_recipe_ingredients',
  'cook_by_vegetables': 'mode_cook_by_vegetables',
  'cook_by_spices': 'mode_cook_by_spices',
  'cook_by_available': 'mode_cook_by_available',
  'budget_meals': 'mode_budget_meals',
  'healthy_meals': 'mode_healthy_meals',
  'quick_meals': 'mode_quick_meals',
  'kids_meals': 'mode_kids_meals',
  'guest_meals': 'mode_guest_meals',
  'weekly_meal_plan': 'mode_weekly_meal_plan',
  'ramadan_list': 'mode_ramadan_list',
  'travel_list': 'mode_travel_list',
  'cleaning_list': 'mode_cleaning_list',
};

enum AiMode {
  shoppingSuggestions('shopping_suggestions'),
  whatToCook('what_to_cook'),
  recipeIngredients('recipe_ingredients'),
  cookByVegetables('cook_by_vegetables'),
  cookBySpices('cook_by_spices'),
  cookByAvailable('cook_by_available'),
  budgetMeals('budget_meals'),
  healthyMeals('healthy_meals'),
  quickMeals('quick_meals'),
  kidsMeals('kids_meals'),
  guestMeals('guest_meals'),
  weeklyMealPlan('weekly_meal_plan'),
  ramadanList('ramadan_list'),
  travelList('travel_list'),
  cleaningList('cleaning_list');

  final String apiValue;

  const AiMode(this.apiValue);

  String get translationKey =>
      _translationKeys[apiValue] ?? 'mode_shopping_suggestions';

  String label(String languageCode) {
    return AppLocalizations(Locale(languageCode)).translate(translationKey);
  }

  static AiMode fromApiValue(String value) {
    return AiMode.values.firstWhere(
      (m) => m.apiValue == value,
      orElse: () => AiMode.shoppingSuggestions,
    );
  }
}
