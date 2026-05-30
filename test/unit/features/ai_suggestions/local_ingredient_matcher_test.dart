import 'package:flutter_test/flutter_test.dart';
import 'package:beity/features/ai_suggestions/data/models/local_food_key_mapper.dart';
import 'package:beity/features/ai_suggestions/domain/entities/local_ingredient_context.dart';
import 'package:beity/features/ai_suggestions/domain/entities/ai_recipe_ingredient.dart';
import 'package:beity/features/inventory/domain/entities/inventory_item.dart';
import 'package:beity/features/shopping_lists/domain/entities/shopping_item.dart';

// Helper class to mock items dynamically since the builder supports duck-typing List<dynamic>
class MockInventoryItem extends InventoryItem {
  MockInventoryItem({required super.name, required super.quantity, String? unit})
      : super(
          id: 'mock-inv-id',
          homeId: 'mock-home-id',
          unitId: unit,
          createdBy: 'mock-user-id',
          updatedBy: 'mock-user-id',
          createdAt: DateTime.now(),
        );
}

class MockShoppingItem extends ShoppingItem {
  MockShoppingItem({
    required super.name,
    required super.quantity,
    String? unit,
    super.isPurchased = false,
  }) : super(
          id: 'mock-shop-id',
          shoppingListId: 'mock-list-id',
          unitId: unit,
          createdBy: 'mock-user-id',
          createdAt: DateTime.now(),
        );
}

// Extracted from provider for unit testing directly
AiRecipeIngredient testMatchIngredientLocal(
  AiRecipeIngredient ing,
  LocalIngredientContext? context,
  String languageCode,
) {
  if (context == null) {
    return ing;
  }

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

  LocalIngredientRef? findBestRef(List<LocalIngredientRef> refs) {
    for (final ref in refs) {
      if (ref.foodKey == aiFoodKey) {
        return ref;
      }
    }
    // Synonym fallback check on normalized names
    final normAiName = LocalFoodKeyMapper.normalize(ing.name);
    for (final ref in refs) {
      final normRefName = LocalFoodKeyMapper.normalize(ref.displayName);
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

  final nameMatch = LocalFoodKeyMapper.match(ing.name);
  final isUnknown = nameMatch.foodKey.startsWith('custom:') || nameMatch.method == 'unknown';

  return ing.copyWith(
    foodKey: aiFoodKey,
    displayName: ing.name,
    status: isUnknown ? IngredientStatus.unknown : IngredientStatus.missing,
    reason: isUnknown 
        ? (languageCode == 'ar' ? 'غير معروف' : 'Unknown status')
        : (languageCode == 'ar' ? 'ناقص' : 'Missing'),
  );
}

void main() {
  group('LocalIngredientMatcher & LocalFoodKeyMapper Tests', () {
    test('Scenario 1: AI returns tomatoes and mapper translates to tomato', () {
      final keyResult = LocalFoodKeyMapper.normalizeFoodKey('tomatoes');
      expect(keyResult, equals('tomato'));

      final rawKeyResult = LocalFoodKeyMapper.normalizeFoodKey('fresh_red_tomatoes');
      expect(rawKeyResult, equals('tomato'));
    });

    test('Scenario 2: AI returns unknown food key but name is "بندورة" which is in inventory => available', () {
      final context = LocalIngredientContextBuilder.build(
        inventoryItems: [
          MockInventoryItem(name: 'بندورة', quantity: 3, unit: 'حبة'),
        ],
        currentListItems: [],
        currentListName: 'قائمتي',
        otherListsItems: {},
      );

      const ing = AiRecipeIngredient(
        name: 'بندورة',
        foodKey: null, // AI returned null or unknown
      );

      final matched = testMatchIngredientLocal(ing, context, 'ar');
      expect(matched.status, equals(IngredientStatus.available));
      expect(matched.displayName, equals('بندورة'));
      expect(matched.foodKey, equals('tomato'));
    });

    test('Scenario 3: Item in completed/purchased shopping lists => missing', () {
      final context = LocalIngredientContextBuilder.build(
        inventoryItems: [],
        currentListItems: [
          MockShoppingItem(name: 'طماطم', quantity: 2, isPurchased: true), // Purchased
        ],
        currentListName: 'قائمتي',
        otherListsItems: {
          'قائمة قديمة': [
            MockShoppingItem(name: 'حليب', quantity: 1, isPurchased: true), // Purchased in other list
          ]
        },
      );

      const ingTomato = AiRecipeIngredient(name: 'طماطم');
      final matchedTomato = testMatchIngredientLocal(ingTomato, context, 'ar');
      expect(matchedTomato.status, equals(IngredientStatus.missing));

      const ingMilk = AiRecipeIngredient(name: 'حليب');
      final matchedMilk = testMatchIngredientLocal(ingMilk, context, 'ar');
      expect(matchedMilk.status, equals(IngredientStatus.missing));
    });

    test('Scenario 4: Item exists in both Inventory and Current List => Inventory priority (available)', () {
      final context = LocalIngredientContextBuilder.build(
        inventoryItems: [
          MockInventoryItem(name: 'بندورة', quantity: 2),
        ],
        currentListItems: [
          MockShoppingItem(name: 'طماطم', quantity: 3),
        ],
        currentListName: 'القائمة الحالية',
        otherListsItems: {},
      );

      const ing = AiRecipeIngredient(name: 'بندورة');
      final matched = testMatchIngredientLocal(ing, context, 'ar');
      
      expect(matched.status, equals(IngredientStatus.available));
      expect(matched.reason, contains('المخزن'));
    });

    test('Scenario 5: Item exists in Current List and another list => Current List priority (inCurrentList)', () {
      final context = LocalIngredientContextBuilder.build(
        inventoryItems: [],
        currentListItems: [
          MockShoppingItem(name: 'دجاج', quantity: 1),
        ],
        currentListName: 'عشاء اليوم',
        otherListsItems: {
          'مقاضي الأسبوع': [
            MockShoppingItem(name: 'دجاج', quantity: 2),
          ]
        },
      );

      const ing = AiRecipeIngredient(name: 'دجاج');
      final matched = testMatchIngredientLocal(ing, context, 'ar');

      expect(matched.status, equals(IngredientStatus.inCurrentList));
      expect(matched.sourceListName, equals('عشاء اليوم'));
    });

    test('Scenario 6: Legacy AI returns status: missing, but locally found in Inventory => available', () {
      final context = LocalIngredientContextBuilder.build(
        inventoryItems: [
          MockInventoryItem(name: 'بندورة', quantity: 4),
        ],
        currentListItems: [],
        currentListName: 'قائمتي',
        otherListsItems: {},
      );

      // Legacy response has status: missing, reason: 'غير متوفر'
      const ing = AiRecipeIngredient(
        name: 'طماطم',
        status: IngredientStatus.missing,
        reason: 'غير متوفر في خادم AI',
      );

      final matched = testMatchIngredientLocal(ing, context, 'ar');
      expect(matched.status, equals(IngredientStatus.available));
      expect(matched.reason, equals('متوفر في المخزن'));
    });

    test('Scenario 7: Low confidence match (confidence < 0.75) => unknown status and custom foodKey', () {
      // "صلصة حارة جداً" is not in synonyms map and has low similarity to tomato or chicken
      final matchResult = LocalFoodKeyMapper.match('صلصة حارة جداً جداً جداً');
      expect(matchResult.confidence, lessThan(0.75));
      expect(matchResult.foodKey, startsWith('custom:'));

      final context = LocalIngredientContextBuilder.build(
        inventoryItems: [],
        currentListItems: [],
        currentListName: 'قائمتي',
        otherListsItems: {},
      );

      const ing = AiRecipeIngredient(name: 'صلصة حارة جداً جداً جداً');
      final matched = testMatchIngredientLocal(ing, context, 'ar');

      expect(matched.status, equals(IngredientStatus.unknown));
      expect(matched.foodKey, startsWith('custom:'));
    });

    test('Scenario 8: Present but insufficient inventory quantity (e.g. inventory = 3, recipe = 5) => missing with details', () {
      final context = LocalIngredientContextBuilder.build(
        inventoryItems: [
          MockInventoryItem(name: 'بندورة', quantity: 3, unit: 'حبة'),
        ],
        currentListItems: [],
        currentListName: 'قائمتي',
        otherListsItems: {},
      );

      const ing = AiRecipeIngredient(
        name: 'بندورة',
        quantity: 5,
      );

      final matched = testMatchIngredientLocal(ing, context, 'ar');
      expect(matched.status, equals(IngredientStatus.missing));
      expect(matched.reason, contains('متوفر بالمخزن (3) ولكن ناقص (2 ناقصة)'));
    });
  });
}
