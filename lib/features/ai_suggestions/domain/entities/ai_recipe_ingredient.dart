/// Status of a recipe ingredient relative to what the user already has.
enum IngredientStatus {
  available('available', 'موجود', 'Available'),
  missing('missing', 'ناقص', 'Missing'),
  alreadyInList('already_in_list', 'موجود في القائمة', 'Already in list'),
  optional('optional', 'اختياري', 'Optional'),
  unknown('unknown', 'غير معروف', 'Unknown');

  final String apiValue;
  final String labelAr;
  final String labelEn;

  const IngredientStatus(this.apiValue, this.labelAr, this.labelEn);

  String label(String languageCode) => languageCode == 'ar' ? labelAr : labelEn;

  static IngredientStatus fromApiValue(String? value) {
    if (value == null) return IngredientStatus.unknown;
    return IngredientStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => IngredientStatus.unknown,
    );
  }
}

/// A single ingredient in a recipe, with status and metadata.
class AiRecipeIngredient {
  final String name;
  final double quantity;
  final String? unit;
  final String? category;
  final bool required;
  final IngredientStatus status;
  final String? reason;
  final String? note;

  const AiRecipeIngredient({
    required this.name,
    this.quantity = 1,
    this.unit,
    this.category,
    this.required = true,
    this.status = IngredientStatus.missing,
    this.reason,
    this.note,
  });

  /// Whether this ingredient should be selected by default for adding to the shopping list.
  bool get isSelectedByDefault =>
      status == IngredientStatus.missing && required;
}

/// Meal metadata for a recipe ingredients response.
class AiMealInfo {
  final String name;
  final String description;
  final int servings;
  final int estimatedTimeMinutes;
  final String difficulty;
  final String cuisine;

  const AiMealInfo({
    required this.name,
    this.description = '',
    this.servings = 4,
    this.estimatedTimeMinutes = 30,
    this.difficulty = '',
    this.cuisine = '',
  });
}

/// Summary of ingredient availability.
class ShoppingSummary {
  final int availableCount;
  final int missingCount;
  final int alreadyInListCount;

  const ShoppingSummary({
    this.availableCount = 0,
    this.missingCount = 0,
    this.alreadyInListCount = 0,
  });
}
