# Quickstart: Inventory Phase

**Feature**: 013-inventory-phase  
**Date**: 2026-05-13  
**Status**: Complete

## Overview

This quickstart guide helps you get started with the Inventory feature implementation.

## Prerequisites

1. Completed specs 001-004 (Auth, Homes, Invitations, Categories/Units)
2. Completed specs 005-006 (Shopping Lists/Items) — needed for the shopping list integration
3. Supabase project configured with existing tables
4. Flutter development environment set up

## Setup Steps

### 1. Database Migration

Run the migration to create inventory tables:

```bash
supabase migration up
```

This creates:
- `inventory_items` table with RLS policies
- `inventory_transactions` table with RLS policies
- Required indexes and triggers

### 2. Create Feature Directory Structure

```bash
mkdir -p lib/features/inventory/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}
```

### 3. Implement Data Layer

Start with models and repositories:

1. **Models**: Create Dart classes matching database schema
   - `inventory_item_model.dart`
   - `inventory_transaction_model.dart`

2. **Repositories**: Implement Supabase operations
   - `inventory_repository.dart` (interface)
   - `supabase_inventory_repository.dart` (implementation)

### 4. Implement Domain Layer

Create entities and use cases:

1. **Entities**: Business objects with validation
   - `inventory_item.dart`
   - `inventory_transaction.dart`

2. **Use Cases**: Business logic operations
   - `add_inventory_item_usecase.dart` — Add item with duplicate detection
   - `update_inventory_quantity_usecase.dart` — Update quantity, create transaction, handle zero-removal
   - `delete_inventory_item_usecase.dart` — Soft-delete with confirmation
   - `get_inventory_items_usecase.dart` — Fetch grouped by category
   - `add_to_shopping_list_usecase.dart` — Add low-stock item to shopping list
   - `add_purchased_to_inventory_usecase.dart` — Upsert purchased item into inventory

### 5. Implement Presentation Layer

Build UI components:

1. **Providers**: Riverpod state management
   - `inventory_provider.dart` — Inventory items list with realtime subscription
   - `inventory_transactions_provider.dart` — Transaction history for an item

2. **Screens**: Main UI screens
   - `inventory_screen.dart` — Main inventory list grouped by category
   - `add_inventory_item_screen.dart` — Add new item form with auto-suggest
   - `edit_inventory_item_screen.dart` — Edit item details and threshold
   - `inventory_item_detail_screen.dart` — View item details and transaction history

3. **Widgets**: Reusable UI components
   - `inventory_item_tile.dart` — Item row with name, quantity, low-stock badge
   - `quantity_adjuster_widget.dart` — Plus/minus buttons with unit-aware step
   - `low_stock_badge.dart` — Visual indicator for items at/below threshold
   - `category_group_header.dart` — Category header for grouped list

### 6. Implement Real-time Updates

Add Supabase Realtime subscriptions:

```dart
// In inventory_provider.dart
void subscribeToInventory(String homeId) {
  supabase
    .from('inventory_items')
    .stream(primaryKey: ['id'])
    .eq('home_id', homeId)
    .eq('deleted_at', null)
    .listen((data) {
      state = AsyncData(data);
    });
}
```

### 7. Implement Shopping List Integration

Connect inventory to the existing shopping list feature:

1. **Inventory → Shopping List**: When user taps "Add to Shopping List" on an inventory item, call `add_to_shopping_list_usecase` which:
   - Calculates suggested quantity: `(min_quantity × 2) − current_quantity`
   - Checks if item already exists in the target shopping list (by name + unit)
   - Creates new shopping item or updates existing one

2. **Shopping List → Inventory**: When user marks a shopping item as purchased with "Add to Inventory" toggle on, call `add_purchased_to_inventory_usecase` which:
   - Checks if item already exists in inventory (by name + unit)
   - Creates new inventory item or increases existing quantity
   - Records transaction with reason `shopping_restock`

### 8. Implement Offline Support

Queue inventory mutations in the existing offline queue when offline:

1. Detect connectivity status (reuse existing connectivity service)
2. Queue add/update/delete operations when offline
3. Replay queue when connection is restored
4. Handle conflicts using `updated_at` (last-write-wins)

## Testing

### Unit Tests

```bash
flutter test test/unit/features/inventory/
```

Test coverage should include:
- Repositories (mock Supabase client)
- Use cases (mock repositories)
- Duplicate detection logic
- Zero-quantity removal logic
- Low-stock threshold evaluation
- Restock suggestion calculation

### Widget Tests

```bash
flutter test test/widget/features/inventory/
```

Test coverage should include:
- Inventory item tiles (normal state, low-stock state)
- Quantity adjuster (whole units vs fractional units)
- Category group headers
- Add/edit forms

### Integration Tests

```bash
flutter test test/integration/features/inventory/
```

Test coverage should include:
- Full inventory flow (add item → update quantity → delete)
- Shopping list integration (add from inventory, add from purchased)
- Real-time sync between devices
- Offline queue and replay

## Common Patterns

### Adding an Inventory Item

```dart
final addItemUseCase = ref.read(addInventoryItemUseCaseProvider);
await addItemUseCase(
  homeId: homeId,
  name: 'Rice',
  quantity: 2.5,
  unitId: unitId,
  categoryId: categoryId,
  minQuantity: 1.0,
  notes: 'Basmati, pantry',
);
```

### Updating Quantity with Quick-Adjust

```dart
final updateUseCase = ref.read(updateInventoryQuantityUseCaseProvider);
await updateUseCase(
  itemId: itemId,
  newQuantity: currentQuantity + adjustStep, // +1 for whole units, +0.5 for fractional
  changeReason: 'manual_update',
);
```

### Adding Low-Stock Item to Shopping List

```dart
final addToListUseCase = ref.read(addToShoppingListUseCaseProvider);
await addToListUseCase(
  inventoryItemId: itemId,
  shoppingListId: listId,
  suggestedQuantity: (minQuantity * 2) - currentQuantity,
);
```

### Subscribing to Real-time Updates

```dart
ref.listen(inventoryProvider(homeId), (previous, next) {
  // Handle inventory changes
});
```

## Troubleshooting

### Real-time not working
- Check RLS policies allow SELECT for the user
- Verify Supabase Realtime is enabled for the `inventory_items` table
- Check network connectivity

### Duplicate detection not merging
- Verify name comparison is case-insensitive (`ilike` or lowercased)
- Ensure unit_id matches (not just name)
- Check that `deleted_at IS NULL` filter is applied

### Quick-adjust step wrong for fractional units
- Verify the unit's `is_fractional` flag is correctly set in the `units` table
- Check that the adjuster widget reads the unit type from the item's unit relationship

## Next Steps

After completing the basic implementation:
1. Add inventory search/filter by category
2. Implement inventory item transaction history screen
3. Add bulk operations (clear all, export)
4. Optimize for large inventories (500+ items) with virtualized lists
5. Add Arabic RTL support to all new screens
