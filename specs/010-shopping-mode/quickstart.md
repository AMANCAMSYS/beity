# Quickstart: Shopping Mode

**Feature**: 010-shopping-mode  
**Date**: 2026-05-13

## Overview

Shopping Mode provides a dedicated, fast, distraction-free interface for actively shopping at a store. It's a UI layer over existing shopping list data with session tracking for history.

## Prerequisites

- Shopping Lists (SPEC 005) implemented
- Shopping Items (SPEC 006) implemented
- Categories & Units (SPEC 004) implemented
- Real-time Sync (SPEC 007) implemented

## Database Setup

Run the migration to create the `shopping_mode_sessions` table:

```bash
supabase db push
# or apply migration manually:
# supabase migration up
```

## Feature Structure

```
lib/features/shopping_mode/
├── data/
│   ├── models/
│   │   └── shopping_mode_session_model.dart
│   └── repositories/
│       ├── shopping_mode_repository.dart          # Abstract interface
│       └── supabase_shopping_mode_repository.dart  # Supabase implementation
├── domain/
│   ├── entities/
│   │   └── shopping_mode_session.dart
│   └── usecases/
│       ├── start_shopping_session_usecase.dart
│       ├── end_shopping_session_usecase.dart
│       ├── get_active_session_usecase.dart
│       └── get_shopping_history_usecase.dart
└── presentation/
    ├── providers/
    │   ├── shopping_mode_provider.dart
    │   ├── shopping_mode_items_provider.dart
    │   └── shopping_mode_session_provider.dart
    ├── screens/
    │   └── shopping_mode_screen.dart
    └── widgets/
        ├── shopping_item_card.dart
        ├── shopping_category_group.dart
        ├── shopping_progress_bar.dart
        ├── shopping_quick_add_overlay.dart
        ├── shopping_quantity_controls.dart
        ├── shopping_exit_summary.dart
        └── shopping_mode_search_bar.dart
```

## Key Workflows

### 1. Entering Shopping Mode

1. User opens a shopping list
2. Taps "Start Shopping" button
3. System creates a `shopping_mode_sessions` record
4. System counts total items in list
5. System enables screen keep-awake (`WakelockPlus.enable()`)
6. System navigates to `ShoppingModeScreen`

### 2. Marking Items as Purchased

1. User taps an item card
2. System updates `shopping_items.is_purchased = true`
3. System sets `purchased_by` and `purchased_at`
4. System increments session's `items_purchased_count`
5. Item animates and moves to bottom of its category group
6. Real-time sync propagates to other shoppers

### 3. Adding Items in Shopping Mode

1. User taps floating add button
2. Bottom sheet overlay appears with large text field
3. User types item name (autocomplete from templates)
4. User taps "Add" → item created, field clears for next entry
5. "Add Another" keeps overlay open for consecutive additions

### 4. Exiting Shopping Mode

1. User taps "Done Shopping"
2. If unpurchased items remain → confirmation dialog
3. System shows exit summary (count, list by category, who purchased what)
4. System sets `ended_at` on session
5. System disables screen keep-awake (`WakelockPlus.disable()`)
6. System navigates back to normal shopping list view

## Dependencies

| Package | Purpose |
|---------|---------|
| wakelock_plus | Screen keep-awake during shopping mode |
| flutter_riverpod | State management |
| supabase_flutter | Database and Realtime |

## RTL Support

All widgets must use `Directionality.of(context)` for layout:
- Item cards: Text alignment, icon placement
- Category headers: Collapse arrow direction
- Progress bar: Left-to-right fill direction
- Quick-add overlay: Text field alignment
- Search bar: Icon placement

## Testing

```bash
# Unit tests
flutter test test/unit/features/shopping_mode/

# Widget tests
flutter test test/widget/features/shopping_mode/

# Integration tests
flutter test integration_test/features/shopping_mode/
```
