/// A single meal in a daily plan.
class AiDayMeal {
  final String name;
  final String mealType;
  final String description;
  final List<String> mainIngredients;
  final int estimatedTimeMinutes;

  const AiDayMeal({
    required this.name,
    this.mealType = '',
    this.description = '',
    this.mainIngredients = const [],
    this.estimatedTimeMinutes = 30,
  });
}

/// One day in a weekly meal plan.
class AiPlanDay {
  final String day;
  final List<AiDayMeal> meals;

  const AiPlanDay({required this.day, this.meals = const []});
}

/// A full weekly meal plan.
class AiWeeklyPlan {
  final String summary;
  final List<AiPlanDay> days;

  const AiWeeklyPlan({this.summary = '', this.days = const []});
}
