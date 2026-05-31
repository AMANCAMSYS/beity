import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';

import '../../domain/entities/ai_mode.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/entities/ai_assistant_request.dart';
import '../../domain/entities/ai_recipe_ingredient.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/local_ingredient_context.dart';
import '../../data/models/local_food_key_mapper.dart';
import '../../data/datasources/ai_suggestion_remote_data_source.dart';
import '../../../shopping_lists/data/repositories/shopping_list_repository.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/domain/entities/inventory_item.dart';
import '../../../shopping_lists/domain/entities/shopping_item.dart';
import '../../../shopping_lists/domain/entities/shopping_list.dart';

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
  return AiSuggestionRemoteDataSource(supabaseClient: SupabaseService.client);
});

final aiAssistantProvider = StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  final dataSource = ref.watch(aiAssistantDataSourceProvider);
  final shoppingRepository = ref.watch(shoppingListRepositoryProvider);
  return AiAssistantNotifier(dataSource, shoppingRepository, ref);
});

// ──────────────────── Helper Functions for Local Comparison ────────────────────

String _normalizeIngredientName(String text) {
  var s = text.toLowerCase().trim();
  // Remove Arabic diacritics (tashkeel)
  s = s.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
  // Normalize letters
  s = s.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
  s = s.replaceAll('ة', 'ه').replaceAll('ى', 'ي');
  // Remove numbers and units/words that skew comparison
  final stopwords = [
    'جرام', 'كوب', 'ملعقة', 'كيس', 'علبة', 'حبة', 'قطع', 'قطعة', 'كيلو', 'حبات',
    'مفروم', 'مقطع', 'طازج', 'ناعم', 'ملح', 'فلفل', 'بهارات', 'ماء', 'زيت',
    'chopped', 'sliced', 'fresh', 'ground', 'powder', 'grams', 'kg', 'cup', 'cups', 'spoon', 'spoons',
  ];
  for (final word in stopwords) {
    s = s.replaceAll(word, '');
  }
  // Keep only letters and numbers
  s = s.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

AiRecipeIngredient _matchIngredientLocal(
  AiRecipeIngredient ing,
  LocalIngredientContext? context,
  String languageCode,
) {
  if (context == null) {
    return ing;
  }

  // 1. Resolve and normalize standard food key
  final rawAiFoodKey = ing.foodKey;
  String aiFoodKey = '';
  
  if (rawAiFoodKey != null && rawAiFoodKey.isNotEmpty) {
    aiFoodKey = LocalFoodKeyMapper.normalizeFoodKey(rawAiFoodKey);
  } else {
    final matchResult = LocalFoodKeyMapper.match(ing.name);
    if (matchResult.confidence >= 0.75) {
      aiFoodKey = matchResult.foodKey;
    } else {
      aiFoodKey = 'custom:${LocalFoodKeyMapper.normalize(ing.name).replaceAll(' ', '_')}';
    }
  }

  // Helper to find a matching local ingredient ref
  LocalIngredientRef? findBestRef(List<LocalIngredientRef> refs) {
    // 2a. Exact foodKey match
    for (final ref in refs) {
      if (ref.foodKey == aiFoodKey) {
        return ref;
      }
    }
    // 2b. Synonym/normalized containment check
    final normAiName = _normalizeIngredientName(ing.name);
    for (final ref in refs) {
      final normRefName = _normalizeIngredientName(ref.displayName);
      if (normRefName.isNotEmpty && normAiName.isNotEmpty) {
        if (normRefName == normAiName || normRefName.contains(normAiName) || normAiName.contains(normRefName)) {
          return ref;
        }
      }
    }
    return null;
  }

  // Priority 1: Check Inventory
  final invMatch = findBestRef(context.inventory);
  if (invMatch != null) {
    final reqQty = ing.quantity;
    final invQty = invMatch.quantity ?? 0.0;
    
    if (invQty > 0 && invQty < reqQty) {
      final diff = reqQty - invQty;
      String fmt(double val) => val % 1 == 0 ? val.toInt().toString() : val.toString();
      return ing.copyWith(
        foodKey: aiFoodKey,
        displayName: invMatch.displayName,
        status: IngredientStatus.missing,
        reason: languageCode == 'ar'
            ? 'متوفر بالمخزن (${fmt(invQty)}) ولكن ناقص (${fmt(diff)} ناقصة)'
            : 'Available in inventory (${fmt(invQty)}) but insufficient (${fmt(diff)} missing)',
      );
    }
    
    return ing.copyWith(
      foodKey: aiFoodKey,
      displayName: invMatch.displayName,
      status: IngredientStatus.available,
      reason: languageCode == 'ar' ? 'متوفر في المخزن' : 'Available in inventory',
    );
  }

  // Priority 2: Check Current List
  final currentMatch = findBestRef(context.currentList);
  if (currentMatch != null) {
    return ing.copyWith(
      foodKey: aiFoodKey,
      displayName: currentMatch.displayName,
      status: IngredientStatus.inCurrentList,
      reason: languageCode == 'ar' ? 'موجود في القائمة الحالية' : 'Already in current list',
      sourceListName: currentMatch.listName,
    );
  }

  // Priority 3: Check Other Active Lists
  final otherMatch = findBestRef(context.otherActiveLists);
  if (otherMatch != null) {
    return ing.copyWith(
      foodKey: aiFoodKey,
      displayName: otherMatch.displayName,
      status: IngredientStatus.inOtherList,
      reason: languageCode == 'ar' 
          ? 'موجود في قائمة: ${otherMatch.listName}' 
          : 'Already in list: ${otherMatch.listName}',
      sourceListName: otherMatch.listName,
    );
  }

  // High confidence vs low confidence missing check
  final nameMatch = LocalFoodKeyMapper.match(ing.name);
  final isUnknown = nameMatch.foodKey.startsWith('custom:') || nameMatch.method == 'unknown';

  // Fallback: Missing or Unknown
  return ing.copyWith(
    foodKey: aiFoodKey,
    displayName: ing.name,
    status: isUnknown ? IngredientStatus.unknown : IngredientStatus.missing,
    reason: isUnknown 
        ? (languageCode == 'ar' ? 'غير معروف' : 'Unknown status')
        : (languageCode == 'ar' ? 'ناقص' : 'Missing'),
  );
}

AiSuggestion _matchSuggestionLocal(
  AiSuggestion ing,
  LocalIngredientContext? context,
  String languageCode,
) {
  if (context == null) {
    return ing;
  }

  // 1. Resolve and normalize standard food key
  String aiFoodKey = 'custom:${LocalFoodKeyMapper.normalize(ing.name).replaceAll(' ', '_')}';
  final matchResult = LocalFoodKeyMapper.match(ing.name);
  if (matchResult.confidence >= 0.75) {
    aiFoodKey = matchResult.foodKey;
  }

  // Helper to find a matching local ingredient ref
  LocalIngredientRef? findBestRef(List<LocalIngredientRef> refs) {
    // 2a. Exact foodKey match
    for (final ref in refs) {
      if (ref.foodKey == aiFoodKey) {
        return ref;
      }
    }
    // 2b. Synonym/normalized containment check
    final normAiName = _normalizeIngredientName(ing.name);
    for (final ref in refs) {
      final normRefName = _normalizeIngredientName(ref.displayName);
      if (normRefName.isNotEmpty && normAiName.isNotEmpty) {
        if (normRefName == normAiName || normRefName.contains(normAiName) || normAiName.contains(normRefName)) {
          return ref;
        }
      }
    }
    return null;
  }

  // Priority 1: Check Inventory
  final invMatch = findBestRef(context.inventory);
  if (invMatch != null) {
    final reqQty = ing.quantity ?? 1.0;
    final invQty = invMatch.quantity ?? 0.0;
    
    if (invQty > 0 && invQty < reqQty) {
      final diff = reqQty - invQty;
      String fmt(double val) => val % 1 == 0 ? val.toInt().toString() : val.toString();
      return ing.copyWith(
        displayName: invMatch.displayName,
        status: IngredientStatus.missing,
        reason: languageCode == 'ar'
            ? 'متوفر بالمخزن (${fmt(invQty)}) ولكن ناقص (${fmt(diff)} ناقصة)'
            : 'Available in inventory (${fmt(invQty)}) but insufficient (${fmt(diff)} missing)',
      );
    }
    
    return ing.copyWith(
      displayName: invMatch.displayName,
      status: IngredientStatus.available,
      reason: languageCode == 'ar' ? 'متوفر في المخزن' : 'Available in inventory',
    );
  }

  // Priority 2: Check Current List
  final currentMatch = findBestRef(context.currentList);
  if (currentMatch != null) {
    return ing.copyWith(
      displayName: currentMatch.displayName,
      status: IngredientStatus.inCurrentList,
      reason: languageCode == 'ar' ? 'موجود في القائمة الحالية' : 'Already in current list',
      sourceListName: currentMatch.listName,
    );
  }

  // Priority 3: Check Other Active Lists
  final otherMatch = findBestRef(context.otherActiveLists);
  if (otherMatch != null) {
    return ing.copyWith(
      displayName: otherMatch.displayName,
      status: IngredientStatus.inOtherList,
      reason: languageCode == 'ar' 
          ? 'موجود في قائمة: ${otherMatch.listName}' 
          : 'Already in list: ${otherMatch.listName}',
      sourceListName: otherMatch.listName,
    );
  }

  // High confidence vs low confidence missing check
  final nameMatch = LocalFoodKeyMapper.match(ing.name);
  final isUnknown = nameMatch.foodKey.startsWith('custom:') || nameMatch.method == 'unknown';

  // Fallback: Missing or Unknown
  return ing.copyWith(
    displayName: ing.name,
    status: isUnknown ? IngredientStatus.unknown : IngredientStatus.missing,
    reason: ing.reason ?? (isUnknown 
        ? (languageCode == 'ar' ? 'غير معروف' : 'Unknown status')
        : (languageCode == 'ar' ? 'ناقص' : 'Missing')),
  );
}

// ──────────────────── Notifier ────────────────────

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final AiSuggestionRemoteDataSource _dataSource;
  final ShoppingListRepository _shoppingRepository;
  final Ref _ref;

  AiAssistantNotifier(this._dataSource, this._shoppingRepository, this._ref) : super(const AiAssistantIdle());

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

        if (response is AiRecipeIngredientsResponse) {
        // Build structural local context in memory without hitting the database
        LocalIngredientContext? localContext;
        final homeId = request.homeId ?? '';
        final listId = request.listId ?? '';
        if (homeId.isNotEmpty) {
          try {
            List<InventoryItem> inventoryItems = [];
            try {
              inventoryItems = _ref.read(inventoryItemsProvider(homeId)).valueOrNull ?? [];
            } catch (_) {}
            
            List<ShoppingList> lists = [];
            try {
              lists = _ref.read(shoppingListsProvider(homeId)).valueOrNull ?? [];
            } catch (_) {}
            final uncompletedLists = lists.where((l) => !l.isArchived).toList();

            List<ShoppingItem> currentListItems = [];
            String currentListName = request.listTitle ?? 'قائمة';
            final Map<String, List<ShoppingItem>> otherListsItems = {};

            for (final list in uncompletedLists) {
              List<ShoppingItem> items = [];
              try {
                items = _ref.read(shoppingItemsProvider(list.id)).valueOrNull ?? [];
              } catch (_) {}
              if (list.id == listId) {
                currentListItems = items;
                currentListName = list.name;
              } else {
                otherListsItems[list.name] = items;
              }
            }

            localContext = LocalIngredientContextBuilder.build(
              inventoryItems: inventoryItems,
              currentListItems: currentListItems,
              currentListName: currentListName,
              otherListsItems: otherListsItems,
            );
          } catch (e) {
            // ignore
          }
        }

        final localeCode = request.language;

        // Map required and optional ingredients using advanced local matching logic
        final updatedIngredients = response.ingredients.map((ing) {
          return _matchIngredientLocal(ing, localContext, localeCode);
        }).toList();

        final updatedOptionalIngredients = response.optionalIngredients.map((ing) {
          final matched = _matchIngredientLocal(ing, localContext, localeCode);
          if (matched.status == IngredientStatus.available || 
              matched.status == IngredientStatus.inCurrentList || 
              matched.status == IngredientStatus.inOtherList) {
            return matched;
          }
          return matched.copyWith(status: IngredientStatus.optional);
        }).toList();

        // Calculate shopping summary based on priority statuses
        int availableCount = 0;
        int missingCount = 0;
        int alreadyInListCount = 0;

        for (final ing in updatedIngredients) {
          if (ing.required) {
            switch (ing.status) {
              case IngredientStatus.available:
                availableCount++;
                break;
              case IngredientStatus.inCurrentList:
              case IngredientStatus.alreadyInList:
              case IngredientStatus.inOtherList:
                alreadyInListCount++;
                break;
              case IngredientStatus.missing:
              case IngredientStatus.unknown:
              case IngredientStatus.optional:
                missingCount++;
                break;
            }
          }
        }

        final updatedSummary = ShoppingSummary(
          availableCount: availableCount,
          missingCount: missingCount,
          alreadyInListCount: alreadyInListCount,
        );

        // Rebuild response with local matching calculations
        final localMatchedResponse = AiRecipeIngredientsResponse(
          meal: response.meal,
          ingredients: updatedIngredients,
          optionalIngredients: updatedOptionalIngredients,
          cookingStepsPreview: response.cookingStepsPreview,
          shoppingSummary: updatedSummary,
        );

        // Auto-select missing/unknown ingredients for recipe responses
        Set<int> autoSelected = {};
        for (int i = 0; i < updatedIngredients.length; i++) {
          if (updatedIngredients[i].isSelectedByDefault) {
            autoSelected.add(i);
          }
        }

        state = AiAssistantResult(localMatchedResponse, selectedIngredientIndices: autoSelected);
        return;
      }

      if (response is AiShoppingSuggestionsResponse) {
        // Build structural local context in memory without hitting the database
        LocalIngredientContext? localContext;
        final homeId = request.homeId ?? '';
        final listId = request.listId ?? '';
        if (homeId.isNotEmpty) {
          try {
            List<InventoryItem> inventoryItems = [];
            try {
              inventoryItems = _ref.read(inventoryItemsProvider(homeId)).valueOrNull ?? [];
            } catch (_) {}
            
            List<ShoppingList> lists = [];
            try {
              lists = _ref.read(shoppingListsProvider(homeId)).valueOrNull ?? [];
            } catch (_) {}
            final uncompletedLists = lists.where((l) => !l.isArchived).toList();

            List<ShoppingItem> currentListItems = [];
            String currentListName = request.listTitle ?? 'قائمة';
            final Map<String, List<ShoppingItem>> otherListsItems = {};

            for (final list in uncompletedLists) {
              List<ShoppingItem> items = [];
              try {
                items = _ref.read(shoppingItemsProvider(list.id)).valueOrNull ?? [];
              } catch (_) {}
              if (list.id == listId) {
                currentListItems = items;
                currentListName = list.name;
              } else {
                otherListsItems[list.name] = items;
              }
            }

            localContext = LocalIngredientContextBuilder.build(
              inventoryItems: inventoryItems,
              currentListItems: currentListItems,
              currentListName: currentListName,
              otherListsItems: otherListsItems,
            );
          } catch (e) {
            // ignore
          }
        }

        final localeCode = request.language;

        // Map required and optional ingredients using advanced local matching logic
        final updatedSuggestions = response.suggestions.map((s) {
          return _matchSuggestionLocal(s, localContext, localeCode);
        }).toList();

        final localMatchedResponse = AiShoppingSuggestionsResponse(suggestions: updatedSuggestions);

        // Pre-select only missing and unknown suggestions by default
        Set<int> autoSelected = {};
        for (int i = 0; i < updatedSuggestions.length; i++) {
          if (updatedSuggestions[i].isSelectedByDefault) {
            autoSelected.add(i);
          }
        }

        state = AiAssistantResult(localMatchedResponse, selectedIngredientIndices: autoSelected);
        return;
      }

      state = AiAssistantResult(response);
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
    String? homeId,
    String? listId,
    List<String> existingShoppingItems = const [],
    List<String> inventoryItems = const [],
    Map<String, String> userTerms = const {},
    String? homeType,
    String? listTitle,
    String? country,
    String? dialect,
  }) async {
    final String prompt;
    if (language == 'ar') {
      prompt = 'أعطني مكونات وجبة "$mealName" بالتفصيل وبالمقادير الدقيقة مع خطوات الطبخ بالتفصيل خطوة بخطوة';
    } else if (language == 'tr') {
      prompt = '"$mealName" yemeğinin detaylı malzemelerini, ölçülerini ve adım adım tarifini/hazırlanış adımlarını ver.';
    } else {
      prompt = 'Give me the detailed ingredients, precise measurements, and step-by-step cooking instructions for "$mealName".';
    }

    final request = AiAssistantRequest(
      mode: AiMode.recipeIngredients,
      userPrompt: prompt,
      language: language,
      homeId: homeId,
      listId: listId,
      existingShoppingItems: existingShoppingItems,
      inventoryItems: inventoryItems,
      userTerms: userTerms,
      homeType: homeType,
      listTitle: listTitle,
      country: country,
      dialect: dialect,
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
    if (currentState is AiAssistantResult) {
      if (currentState.response is AiRecipeIngredientsResponse) {
        final recipe = currentState.response as AiRecipeIngredientsResponse;
        final indices = <int>{};
        for (int i = 0; i < recipe.ingredients.length; i++) {
          if (recipe.ingredients[i].status == IngredientStatus.missing) {
            indices.add(i);
          }
        }
        state = currentState.copyWith(selectedIngredientIndices: indices);
      } else if (currentState.response is AiShoppingSuggestionsResponse) {
        final shopping = currentState.response as AiShoppingSuggestionsResponse;
        final indices = <int>{};
        for (int i = 0; i < shopping.suggestions.length; i++) {
          if (shopping.suggestions[i].status == IngredientStatus.missing ||
              shopping.suggestions[i].status == IngredientStatus.unknown) {
            indices.add(i);
          }
        }
        state = currentState.copyWith(selectedIngredientIndices: indices);
      }
    }
  }

  /// Deselect all ingredients.
  void deselectAll() {
    final currentState = state;
    if (currentState is AiAssistantResult) {
      state = currentState.copyWith(selectedIngredientIndices: {});
    }
  }

  /// Get selected ingredients (for recipe or shopping suggestions responses).
  List<AiRecipeIngredient> getSelectedIngredients() {
    final currentState = state;
    if (currentState is AiAssistantResult) {
      if (currentState.response is AiRecipeIngredientsResponse) {
        final recipe = currentState.response as AiRecipeIngredientsResponse;
        return currentState.selectedIngredientIndices
            .where((i) => i < recipe.ingredients.length)
            .map((i) => recipe.ingredients[i])
            .toList();
      } else if (currentState.response is AiShoppingSuggestionsResponse) {
        final shopping = currentState.response as AiShoppingSuggestionsResponse;
        return currentState.selectedIngredientIndices
            .where((i) => i < shopping.suggestions.length)
            .map((i) {
              final s = shopping.suggestions[i];
              return AiRecipeIngredient(
                name: s.name,
                quantity: s.quantity ?? 1.0,
                unit: s.unit ?? '',
                required: true,
                status: IngredientStatus.missing,
                reason: s.reason,
              );
            })
            .toList();
      }
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
          name: ingredient.displayName ?? ingredient.name,
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
