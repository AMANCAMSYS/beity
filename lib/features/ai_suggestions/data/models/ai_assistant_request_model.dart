import '../../domain/entities/ai_assistant_request.dart';

class AiAssistantRequestModel {
  final AiAssistantRequest entity;

  const AiAssistantRequestModel(this.entity);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'mode': entity.mode.apiValue,
      'userPrompt': entity.userPrompt.trim(),
      'language': entity.language,
    };

    // Include homeId and listId for home membership verification
    if (entity.homeId != null && entity.homeId!.isNotEmpty) {
      json['homeId'] = entity.homeId;
    }
    if (entity.listId != null && entity.listId!.isNotEmpty) {
      json['listId'] = entity.listId;
    }

    // Only include non-null, non-empty optional fields
    if (entity.homeType != null && entity.homeType!.isNotEmpty) {
      json['homeType'] = entity.homeType;
    }
    if (entity.listTitle != null && entity.listTitle!.isNotEmpty) {
      json['listTitle'] = entity.listTitle;
    }
    if (entity.existingShoppingItems.isNotEmpty) {
      json['existingShoppingItems'] = entity.existingShoppingItems.take(100).toList();
    }
    if (entity.inventoryItems.isNotEmpty) {
      json['inventoryItems'] = entity.inventoryItems.take(100).toList();
    }
    if (entity.servings != null && entity.servings! > 0) {
      json['servings'] = entity.servings;
    }
    if (entity.preferredCuisine != null && entity.preferredCuisine!.isNotEmpty) {
      json['preferredCuisine'] = entity.preferredCuisine;
    }
    if (entity.dietaryPreference != null && entity.dietaryPreference!.isNotEmpty) {
      json['dietaryPreference'] = entity.dietaryPreference;
    }
    if (entity.budgetLevel != null && entity.budgetLevel!.isNotEmpty) {
      json['budgetLevel'] = entity.budgetLevel;
    }
    if (entity.maxPreparationTimeMinutes != null && entity.maxPreparationTimeMinutes! > 0) {
      json['maxPreparationTimeMinutes'] = entity.maxPreparationTimeMinutes;
    }
    if (entity.availableVegetables.isNotEmpty) {
      json['availableVegetables'] = entity.availableVegetables.take(20).toList();
    }
    if (entity.availableSpices.isNotEmpty) {
      json['availableSpices'] = entity.availableSpices.take(20).toList();
    }
    if (entity.availableProteins.isNotEmpty) {
      json['availableProteins'] = entity.availableProteins.take(20).toList();
    }
    if (entity.availableCarbs.isNotEmpty) {
      json['availableCarbs'] = entity.availableCarbs.take(20).toList();
    }
    if (entity.excludedIngredients.isNotEmpty) {
      json['excludedIngredients'] = entity.excludedIngredients.take(20).toList();
    }
    if (entity.occasion != null && entity.occasion!.isNotEmpty) {
      json['occasion'] = entity.occasion;
    }
    if (entity.mealType != null && entity.mealType!.isNotEmpty) {
      json['mealType'] = entity.mealType;
    }
    if (entity.cookingSkillLevel != null && entity.cookingSkillLevel!.isNotEmpty) {
      json['cookingSkillLevel'] = entity.cookingSkillLevel;
    }
    if (entity.country != null && entity.country!.isNotEmpty) {
      json['country'] = entity.country;
    }
    if (entity.dialect != null && entity.dialect!.isNotEmpty) {
      json['dialect'] = entity.dialect;
    }
    if (entity.userTerms.isNotEmpty) {
      json['user_terms'] = entity.userTerms;
    }

    return json;
  }
}
