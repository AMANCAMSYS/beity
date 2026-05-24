import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/ai_mode.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/entities/ai_assistant_request.dart';
import '../../domain/entities/ai_recipe_ingredient.dart';
import '../../data/datasources/ai_suggestion_remote_data_source.dart';
import '../../../shopping_lists/data/repositories/shopping_list_repository.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';

// ──────────────────── State ────────────────────

sealed class AiAssistantState {
  const AiAssistantState();
}

class AiAssistantIdle extends AiAssistantState {
  const AiAssistantIdle();
}

class AiAssistantLoading extends AiAssistantState {
  const AiAssistantLoading();
}

class AiAssistantResult extends AiAssistantState {
  final AiResponse response;
  final Set<int> selectedIngredientIndices;

  const AiAssistantResult(this.response, {this.selectedIngredientIndices = const {}});

  AiAssistantResult copyWith({AiResponse? response, Set<int>? selectedIngredientIndices}) {
    return AiAssistantResult(
      response ?? this.response,
      selectedIngredientIndices: selectedIngredientIndices ?? this.selectedIngredientIndices,
    );
  }
}

class AiAssistantError extends AiAssistantState {
  final String message;
  const AiAssistantError(this.message);
}

class AiAssistantAddingItems extends AiAssistantState {
  final AiResponse response;
  final Set<int> selectedIngredientIndices;

  const AiAssistantAddingItems(this.response, this.selectedIngredientIndices);
}

// ──────────────────── Providers ────────────────────

final aiAssistantDataSourceProvider = Provider<AiSuggestionRemoteDataSource>((ref) {
  return AiSuggestionRemoteDataSource(supabaseClient: Supabase.instance.client);
});

final aiAssistantProvider = StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  final dataSource = ref.watch(aiAssistantDataSourceProvider);
  final shoppingRepository = ref.watch(shoppingListRepositoryProvider);
  return AiAssistantNotifier(dataSource, shoppingRepository);
});

// ──────────────────── Notifier ────────────────────

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final AiSuggestionRemoteDataSource _dataSource;
  final ShoppingListRepository _shoppingRepository;

  AiAssistantNotifier(this._dataSource, this._shoppingRepository) : super(const AiAssistantIdle());

  /// Send a request to the AI assistant.
  Future<void> sendRequest(AiAssistantRequest request) async {
    final errors = request.validate();
    if (errors.isNotEmpty) {
      state = AiAssistantError(errors.first);
      return;
    }

    state = const AiAssistantLoading();

    try {
      final response = await _dataSource.fetchAssistantResponse(request);

      if (response is AiErrorResponse) {
        state = AiAssistantError(response.message);
        return;
      }

      // Auto-select missing ingredients for recipe responses
      Set<int> autoSelected = {};
      if (response is AiRecipeIngredientsResponse) {
        for (int i = 0; i < response.ingredients.length; i++) {
          if (response.ingredients[i].isSelectedByDefault) {
            autoSelected.add(i);
          }
        }
      }

      state = AiAssistantResult(response, selectedIngredientIndices: autoSelected);
    } on AiValidationException catch (e) {
      state = AiAssistantError(e.message);
    } on AiServiceException catch (e) {
      state = AiAssistantError(e.message);
    } catch (e) {
      state = const AiAssistantError('تعذر إنشاء الاقتراحات، حاول مرة أخرى');
    }
  }

  /// Ask for recipe ingredients for a specific meal (Network Call).
  Future<void> getRecipeIngredients({
    required String mealName,
    required String language,
    List<String> existingShoppingItems = const [],
    List<String> inventoryItems = const [],
    String? homeType,
    String? listTitle,
  }) async {
    final request = AiAssistantRequest(
      mode: AiMode.recipeIngredients,
      userPrompt: 'مكونات وجبة "$mealName" بالتفصيل وبالمقادير الدقيقة',
      language: language,
      existingShoppingItems: existingShoppingItems,
      inventoryItems: inventoryItems,
      homeType: homeType,
      listTitle: listTitle,
    );
    await sendRequest(request);
  }

  /// Instantly show ingredients using local data without hitting the AI.
  void showMealIngredientsInstantly({
    required String mealName,
    required String description,
    required List<String> mainIngredients,
    int estimatedTimeMinutes = 30,
    int servings = 4,
  }) {
    final ingredients = mainIngredients.map((name) => AiRecipeIngredient(
      name: name,
      quantity: 1,
      unit: '',
      required: true,
      status: IngredientStatus.missing,
    )).toList();

    final response = AiRecipeIngredientsResponse(
      meal: AiMealInfo(
        name: mealName,
        description: description,
        servings: servings,
        estimatedTimeMinutes: estimatedTimeMinutes,
        difficulty: 'متوسط',
        cuisine: 'متنوع',
      ),
      ingredients: ingredients,
      optionalIngredients: [],
      cookingStepsPreview: [
        'المعلومات المتوفرة حالياً هي المكونات الأساسية فقط.',
        'يمكنك إضافة هذه المكونات إلى قائمة التسوق الخاصة بك.'
      ],
      shoppingSummary: ShoppingSummary(
        availableCount: 0, 
        missingCount: ingredients.length, 
        alreadyInListCount: 0
      ),
    );

    // Auto-select all ingredients
    Set<int> autoSelected = {};
    for (int i = 0; i < ingredients.length; i++) {
      autoSelected.add(i);
    }

    state = AiAssistantResult(response, selectedIngredientIndices: autoSelected);
  }

  /// Toggle ingredient selection.
  void toggleIngredientSelection(int index) {
    final currentState = state;
    if (currentState is AiAssistantResult) {
      final newSelection = Set<int>.from(currentState.selectedIngredientIndices);
      if (newSelection.contains(index)) {
        newSelection.remove(index);
      } else {
        newSelection.add(index);
      }
      state = currentState.copyWith(selectedIngredientIndices: newSelection);
    }
  }

  /// Select all missing ingredients.
  void selectAllMissing() {
    final currentState = state;
    if (currentState is AiAssistantResult && currentState.response is AiRecipeIngredientsResponse) {
      final recipe = currentState.response as AiRecipeIngredientsResponse;
      final indices = <int>{};
      for (int i = 0; i < recipe.ingredients.length; i++) {
        if (recipe.ingredients[i].status == IngredientStatus.missing) {
          indices.add(i);
        }
      }
      state = currentState.copyWith(selectedIngredientIndices: indices);
    }
  }

  /// Deselect all ingredients.
  void deselectAll() {
    final currentState = state;
    if (currentState is AiAssistantResult) {
      state = currentState.copyWith(selectedIngredientIndices: {});
    }
  }

  /// Get selected ingredients (for recipe responses).
  List<AiRecipeIngredient> getSelectedIngredients() {
    final currentState = state;
    if (currentState is AiAssistantResult && currentState.response is AiRecipeIngredientsResponse) {
      final recipe = currentState.response as AiRecipeIngredientsResponse;
      return currentState.selectedIngredientIndices
          .where((i) => i < recipe.ingredients.length)
          .map((i) => recipe.ingredients[i])
          .toList();
    }
    return [];
  }

  /// Set adding state (while items are being added to shopping list).
  void setAddingState() {
    final currentState = state;
    if (currentState is AiAssistantResult) {
      state = AiAssistantAddingItems(currentState.response, currentState.selectedIngredientIndices);
    }
  }

  /// Add selected ingredients to a shopping list.
  Future<bool> addSelectedToShoppingList(String listId) async {
    final selectedIngredients = getSelectedIngredients();
    if (selectedIngredients.isEmpty) return false;

    final currentState = state;
    if (currentState is! AiAssistantResult) return false;

    state = AiAssistantAddingItems(currentState.response, currentState.selectedIngredientIndices);

    try {
      for (final ingredient in selectedIngredients) {
        await _shoppingRepository.createShoppingItem(
          listId: listId,
          name: ingredient.name,
          quantity: ingredient.quantity,
          notes: ingredient.reason,
        );
      }
      state = const AiAssistantIdle();
      return true;
    } catch (e) {
      state = AiAssistantError('حدث خطأ أثناء إضافة العناصر: ${e.toString()}');
      return false;
    }
  }

  /// Reset to idle.
  void reset() {
    state = const AiAssistantIdle();
  }
}
