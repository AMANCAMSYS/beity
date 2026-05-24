/// All AI assistant modes supported by the cooking & grocery assistant.
enum AiMode {
  shoppingSuggestions('shopping_suggestions', 'اقتراح عناصر مشتريات', 'Shopping Suggestions'),
  whatToCook('what_to_cook', 'ماذا أطبخ؟', 'What to Cook?'),
  recipeIngredients('recipe_ingredients', 'مكونات طبخة معينة', 'Recipe Ingredients'),
  cookByVegetables('cook_by_vegetables', 'طبخات حسب الخضار', 'Cook by Vegetables'),
  cookBySpices('cook_by_spices', 'طبخات حسب البهارات', 'Cook by Spices'),
  cookByAvailable('cook_by_available', 'طبخات حسب الموجود', 'Cook by Available'),
  budgetMeals('budget_meals', 'طبخات اقتصادية', 'Budget Meals'),
  healthyMeals('healthy_meals', 'طبخات صحية', 'Healthy Meals'),
  quickMeals('quick_meals', 'طبخات سريعة', 'Quick Meals'),
  kidsMeals('kids_meals', 'وجبات للأطفال', 'Kids Meals'),
  guestMeals('guest_meals', 'وجبات للضيوف', 'Guest Meals'),
  weeklyMealPlan('weekly_meal_plan', 'خطة وجبات أسبوعية', 'Weekly Meal Plan'),
  ramadanList('ramadan_list', 'قائمة رمضان', 'Ramadan List'),
  travelList('travel_list', 'قائمة سفر', 'Travel List'),
  cleaningList('cleaning_list', 'قائمة تنظيف', 'Cleaning List');

  final String apiValue;
  final String labelAr;
  final String labelEn;

  const AiMode(this.apiValue, this.labelAr, this.labelEn);

  String label(String languageCode) => languageCode == 'ar' ? labelAr : labelEn;

  static AiMode fromApiValue(String value) {
    return AiMode.values.firstWhere(
      (m) => m.apiValue == value,
      orElse: () => AiMode.shoppingSuggestions,
    );
  }
}
