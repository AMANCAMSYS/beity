import '../../data/models/local_food_key_mapper.dart';
import '../../../inventory/domain/entities/inventory_item.dart';
import '../../../shopping_lists/domain/entities/shopping_item.dart';

/// Represents a reference to a local ingredient from the user's inventory or shopping lists.
class LocalIngredientRef {
  final String foodKey;
  final String displayName;
  final String source; // 'inventory' | 'current_list' | 'other_list'
  final String? listName;
  final double? quantity;
  final String? unit;

  const LocalIngredientRef({
    required this.foodKey,
    required this.displayName,
    required this.source,
    this.listName,
    this.quantity,
    this.unit,
  });

  @override
  String toString() =>
      'LocalIngredientRef(key: $foodKey, name: $displayName, source: $source, listName: $listName)';
}

/// Represents the organized local context parsed from the user's phone database.
class LocalIngredientContext {
  final List<LocalIngredientRef> inventory;
  final List<LocalIngredientRef> currentList;
  final List<LocalIngredientRef> otherActiveLists;

  const LocalIngredientContext({
    this.inventory = const [],
    this.currentList = const [],
    this.otherActiveLists = const [],
  });

  /// Flatten all references into a single list in the correct priority order:
  /// 1. Inventory
  /// 2. Current List
  /// 3. Other Active Lists
  List<LocalIngredientRef> get flatRefs => [
    ...inventory,
    ...currentList,
    ...otherActiveLists,
  ];
}

/// Helper class to construct local ingredient context and build the user terms mapping.
class LocalIngredientContextBuilder {
  static LocalIngredientContext build({
    required List<InventoryItem> inventoryItems,
    required List<ShoppingItem> currentListItems,
    required String currentListName,
    required Map<String, List<ShoppingItem>> otherListsItems,
  }) {
    final List<LocalIngredientRef> inventoryRefs = [];
    final List<LocalIngredientRef> currentRefs = [];
    final List<LocalIngredientRef> otherRefs = [];

    // 1. Inventory Items
    for (final item in inventoryItems) {
      final name = item.name;
      final qty = item.quantity;
      if (qty <= 0) continue;

      final match = LocalFoodKeyMapper.match(name);
      if (match.confidence >= 0.75) {
        inventoryRefs.add(
          LocalIngredientRef(
            foodKey: match.foodKey,
            displayName: name,
            source: 'inventory',
            quantity: qty,
            unit: item.unitId,
          ),
        );
      }
    }

    // 2. Current List Items
    for (final item in currentListItems) {
      final name = item.name;
      final isPurchased = item.isPurchased;
      if (isPurchased) continue;

      final match = LocalFoodKeyMapper.match(name);
      if (match.confidence >= 0.75) {
        currentRefs.add(
          LocalIngredientRef(
            foodKey: match.foodKey,
            displayName: name,
            source: 'current_list',
            listName: currentListName,
            quantity: item.quantity,
            unit: item.unitId,
          ),
        );
      }
    }

    // 3. Other Active Lists
    otherListsItems.forEach((listName, items) {
      for (final item in items) {
        final name = item.name;
        final isPurchased = item.isPurchased;
        if (isPurchased) continue;

        final match = LocalFoodKeyMapper.match(name);
        if (match.confidence >= 0.75) {
          otherRefs.add(
            LocalIngredientRef(
              foodKey: match.foodKey,
              displayName: name,
              source: 'other_list',
              listName: listName,
              quantity: item.quantity,
              unit: item.unitId,
            ),
          );
        }
      }
    });

    return LocalIngredientContext(
      inventory: inventoryRefs,
      currentList: currentRefs,
      otherActiveLists: otherRefs,
    );
  }

  /// Builds the optimized user_terms map for the AI model: Map of food_key to preferred_local_name
  /// Priority:
  /// 1. Inventory Name (highest priority, added last to overwrite)
  /// 2. Current List Name (medium priority)
  /// 3. Other Lists Name (lowest priority, added first)
  static Map<String, String> buildUserTerms(LocalIngredientContext context) {
    final Map<String, String> userTerms = {};

    // 3. Other lists name first (lowest priority)
    for (final ref in context.otherActiveLists) {
      userTerms[ref.foodKey] = ref.displayName;
    }

    // 2. Current list name (medium priority)
    for (final ref in context.currentList) {
      userTerms[ref.foodKey] = ref.displayName;
    }

    // 1. Inventory name (highest priority)
    for (final ref in context.inventory) {
      userTerms[ref.foodKey] = ref.displayName;
    }

    return userTerms;
  }
}
