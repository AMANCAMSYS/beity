# Quickstart: Shopping Lists

**Feature**: 005-shopping-lists  
**Date**: 2026-05-12  
**Status**: Complete

## Overview

This quickstart guide helps you get started with the Shopping Lists feature implementation.

## Prerequisites

1. Completed specs 001-004 (Auth, Homes, Invitations, Categories)
2. Supabase project configured with existing tables
3. Flutter development environment set up

## Setup Steps

### 1. Database Migration

Run the migration to create shopping lists tables:

```bash
# Apply migration
supabase migration up
```

This creates:
- `shopping_lists` table with RLS policies
- `shopping_items` table with RLS policies
- `item_templates` table with RLS policies
- Required indexes and triggers

### 2. Create Feature Directory Structure

```bash
mkdir -p lib/features/shopping_lists/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}
```

### 3. Implement Data Layer

Start with models and repositories:

1. **Models**: Create Dart classes matching database schema
   - `shopping_list_model.dart`
   - `shopping_item_model.dart`
   - `item_template_model.dart`

2. **Repositories**: Implement Supabase operations
   - `shopping_list_repository.dart` (interface)
   - `supabase_shopping_list_repository.dart` (implementation)

### 4. Implement Domain Layer

Create entities and use cases:

1. **Entities**: Business objects with validation
   - `shopping_list.dart`
   - `shopping_item.dart`
   - `item_template.dart`

2. **Use Cases**: Business logic operations
   - `create_shopping_list_usecase.dart`
   - `add_item_usecase.dart`
   - `update_item_usecase.dart`
   - `delete_item_usecase.dart`
   - `mark_item_purchased_usecase.dart`
   - `archive_list_usecase.dart`
   - `delete_list_usecase.dart`
   - `get_shopping_lists_usecase.dart`
   - `get_shopping_items_usecase.dart`
   - `search_items_usecase.dart`

### 5. Implement Presentation Layer

Build UI components:

1. **Providers**: Riverpod state management
   - `shopping_lists_provider.dart`
   - `shopping_items_provider.dart`

2. **Screens**: Main UI screens
   - `shopping_lists_screen.dart` - List of all shopping lists
   - `shopping_list_detail_screen.dart` - View/edit items in a list
   - `add_item_screen.dart` - Add new item form
   - `edit_item_screen.dart` - Edit existing item
   - `list_summary_screen.dart` - Summary view with totals
   - `quick_add_screen.dart` - Add from favorites/templates

3. **Widgets**: Reusable UI components
   - `shopping_list_card_widget.dart`
   - `shopping_item_tile_widget.dart`
   - `item_suggestions_widget.dart`
   - `category_filter_widget.dart`

### 6. Implement Real-time Updates

Add Supabase Realtime subscriptions:

```dart
// In shopping_items_provider.dart
void subscribeToItems(String listId) {
  supabase
    .from('shopping_items')
    .stream(primaryKey: ['id'])
    .eq('shopping_list_id', listId)
    .listen((data) {
      state = AsyncData(data);
    });
}
```

### 7. Implement Notifications

Set up FCM notifications for item updates:

1. Create Supabase Edge Function for notification triggers
2. Configure FCM topic for each shopping list
3. Send notifications when items are added/purchased

### 8. Implement Basic Offline Support

Add offline caching with Isar:

1. Create Isar schemas for shopping lists and items
2. Cache data locally when online
3. Queue mutations when offline
4. Sync when connection restored

## Testing

### Unit Tests

```bash
flutter test test/unit/features/shopping_lists/
```

Test coverage should include:
- Repositories (mock Supabase client)
- Use cases (mock repositories)
- Providers (mock use cases)

### Widget Tests

```bash
flutter test test/widget/features/shopping_lists/
```

Test coverage should include:
- Shopping list cards
- Shopping item tiles
- Add/edit forms

### Integration Tests

```bash
flutter test test/integration/features/shopping_lists/
```

Test coverage should include:
- Full shopping flow (create list → add items → mark purchased)
- Real-time updates between devices
- Offline sync behavior

## Common Patterns

### Adding a New Item

```dart
final addItemUseCase = ref.read(addItemUseCaseProvider);
await addItemUseCase(
  listId: listId,
  name: 'Milk',
  quantity: 2,
  unitId: unitId,
  categoryId: categoryId,
  price: 15.50,
);
```

### Marking Item as Purchased

```dart
final markPurchasedUseCase = ref.read(markItemPurchasedUseCaseProvider);
await markPurchasedUseCase(itemId: itemId);
```

### Subscribing to Real-time Updates

```dart
ref.listen(shoppingItemsProvider(listId), (previous, next) {
  // Handle item updates
});
```

## Troubleshooting

### Real-time not working
- Check RLS policies allow SELECT for the user
- Verify Supabase Realtime is enabled for the table
- Check network connectivity

### Offline sync issues
- Verify Isar schema matches Supabase schema
- Check sync queue is processing items
- Look for conflict resolution errors

### Notifications not received
- Verify FCM token is registered
- Check Edge Function logs
- Ensure notification preferences are enabled

## Next Steps

After completing the basic implementation:
1. Add item suggestions based on purchase history
2. Implement list templates
3. Add summary view with price totals
4. Optimize for large lists (200+ items)
5. Add Arabic RTL support to all new screens
