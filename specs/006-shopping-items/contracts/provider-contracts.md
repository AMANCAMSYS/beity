# Provider & Repository Contracts: Shopping Items

**Feature**: 006-shopping-items  
**Date**: 2026-05-12  
**Status**: Complete

## Overview

Contracts define the interface surface between presentation and domain layers. For this Flutter mobile app, contracts are expressed as Dart interface signatures.

## Repository Contracts

### IShoppingItemRepository

```dart
abstract class IShoppingItemRepository {
  /// Get all items for a shopping list
  Future<List<ShoppingItem>> getItems(String shoppingListId);

  /// Add a new item to a shopping list
  Future<ShoppingItem> addItem({
    required String shoppingListId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  });

  /// Update an existing item
  Future<ShoppingItem> updateItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  });

  /// Delete an item
  Future<void> deleteItem(String itemId);

  /// Toggle purchased status
  Future<ShoppingItem> togglePurchased(String itemId);

  /// Search items by name within a list
  Future<List<ShoppingItem>> searchItems(String shoppingListId, String query);

  /// Get autocomplete suggestions from templates + previous items
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions({
    required String homeId,
    required String query,
    int limit = 10,
  });

  /// Subscribe to real-time changes for a shopping list
  Stream<List<ShoppingItem>> watchItems(String shoppingListId);
}
```

### IItemTemplateRepository

```dart
abstract class IItemTemplateRepository {
  /// Get all templates for a home, sorted by usage_count DESC
  Future<List<ItemTemplate>> getTemplates(String homeId);

  /// Auto-create or update template when item is added (NOT on edit)
  Future<void> syncTemplateOnAdd({
    required String homeId,
    required String name,
    double quantity,
    String? unitId,
    String? categoryId,
  });

  /// Increment usage count when template is used via Quick Add
  Future<void> incrementUsageCount(String templateId);
}
```

## Provider Contracts

### ShoppingItemsProvider

```dart
class ShoppingItemsProvider extends StateNotifier<ShoppingItemsState> {
  /// Load items for a shopping list
  Future<void> loadItems(String shoppingListId);

  /// Add item with duplicate check
  Future<AddItemResult> addItem({
    required String shoppingListId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  });

  /// Update item (does NOT update template)
  Future<void> updateItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  });

  /// Delete item with undo support
  Future<void> deleteItem(String itemId);

  /// Restore last deleted item (within 5 seconds)
  Future<void> undoDelete();

  /// Toggle purchased status
  Future<void> togglePurchased(String itemId);

  /// Search/filter items
  void setFilter({String? searchQuery, String? categoryId});

  /// Clear all filters
  void clearFilters();

  /// Get running total of unpurchased item prices
  double get unpurchasedTotal;
}

enum AddItemResult { success, duplicateWarning, error }
```

### ShoppingItemsState

```dart
class ShoppingItemsState {
  final List<ShoppingItem> items;
  final Map<String, List<ShoppingItem>> groupedItems; // by category
  final List<ShoppingItem> filteredItems;
  final String? searchQuery;
  final String? filterCategoryId;
  final ShoppingItem? lastDeletedItem;
  final DateTime? lastDeletedAt;
  final bool isLoading;
  final String? error;
  final double unpurchasedTotal;
}
```

## Type Definitions

```dart
class AutocompleteSuggestion {
  final String name;
  final double quantity;
  final String? unitName;
  final String? sourceId; // template_id or item_id
  final bool isTemplate;
}
```

## Notes

- All repository methods enforce home membership via RLS (server-side)
- Provider handles client-side duplicate name warning check
- Undo delete uses 5-second timer stored in provider state
- Real-time subscription lifecycle managed by provider (subscribe on load, dispose on unmount)
