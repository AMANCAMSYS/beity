import '../../../../core/localization/app_localizations.dart';

/// Status of a recipe ingredient relative to what the user already has.
enum IngredientStatus {
  available('available'),
  missing('missing'),
  alreadyInList('already_in_list'),
  inCurrentList('in_current_list'),
  inOtherList('in_other_list'),
  optional('optional'),
  unknown('unknown');

  final String apiValue;

  const IngredientStatus(this.apiValue);

  String label(AppLocalizations l10n) => l10n.translate(apiValue);

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
  final String? foodKey;
  final String? displayName;
  final double quantity;
  final String? unit;
  final String? category;
  final bool required;
  final IngredientStatus status;
  final String? reason;
  final String? note;
  final String? sourceListName;

  const AiRecipeIngredient({
    required this.name,
    this.foodKey,
    this.displayName,
    this.quantity = 1,
    this.unit,
    this.category,
    this.required = true,
    this.status = IngredientStatus.missing,
    this.reason,
    this.note,
    this.sourceListName,
  });

  AiRecipeIngredient copyWith({
    String? name,
    String? foodKey,
    String? displayName,
    double? quantity,
    String? unit,
    String? category,
    bool? required,
    IngredientStatus? status,
    String? reason,
    String? note,
    String? sourceListName,
  }) {
    return AiRecipeIngredient(
      name: name ?? this.name,
      foodKey: foodKey ?? this.foodKey,
      displayName: displayName ?? this.displayName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      required: required ?? this.required,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      sourceListName: sourceListName ?? this.sourceListName,
    );
  }

  /// Whether this ingredient should be selected by default for adding to the shopping list.
  bool get isSelectedByDefault =>
      (status == IngredientStatus.missing ||
          status == IngredientStatus.unknown) &&
      required;
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
