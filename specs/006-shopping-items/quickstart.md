# Quickstart: Shopping Items

**Feature**: 006-shopping-items  
**Date**: 2026-05-12

## Prerequisites

- Flutter SDK installed
- Supabase project configured (SPEC 00-04 completed)
- Shopping lists feature working (SPEC 05 completed)
- Categories and units seeded (SPEC 04 completed)

## What This Feature Adds

Enhances the existing `shopping_lists` feature with:
1. Category-based grouping with collapsible headers
2. Duplicate item name warning
3. Autocomplete suggestions (name + quantity + unit)
4. Quick Add from item templates
5. Running price total (unpurchased items only)
6. Search and filter within lists
7. Undo delete (5-second window)
8. Real-time sync for all item changes

## Key Files to Modify

### Presentation Layer (enhance existing)
- `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart` — Add category grouping, search, filter, price total
- `lib/features/shopping_lists/presentation/screens/add_item_screen.dart` — Add autocomplete, duplicate warning, template sync
- `lib/features/shopping_lists/presentation/screens/edit_item_screen.dart` — Ensure no template sync on edit
- `lib/features/shopping_lists/presentation/screens/quick_add_screen.dart` — Enhance template picker
- `lib/features/shopping_lists/presentation/providers/shopping_items_provider.dart` — Add grouping, filtering, undo, price total
- `lib/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart` — Update for grouped display
- `lib/features/shopping_lists/presentation/widgets/item_suggestions_widget.dart` — Enhance autocomplete content
- `lib/features/shopping_lists/presentation/widgets/category_filter_widget.dart` — Add filter functionality

### Domain Layer (enhance existing)
- `lib/features/shopping_lists/domain/usecases/add_item_usecase.dart` — Add duplicate check + template sync
- `lib/features/shopping_lists/domain/usecases/update_item_usecase.dart` — Ensure no template sync
- `lib/features/shopping_lists/domain/usecases/delete_item_usecase.dart` — Add undo support
- `lib/features/shopping_lists/domain/usecases/get_shopping_items_usecase.dart` — Add grouping logic
- `lib/features/shopping_lists/domain/usecases/search_items_usecase.dart` — Add autocomplete source

### Data Layer (enhance existing)
- `lib/features/shopping_lists/data/repositories/supabase_shopping_list_repository.dart` — Add autocomplete query, duplicate check
- `lib/features/shopping_lists/data/repositories/item_template_repository.dart` — Add sync-on-add logic

## Implementation Order

1. **Provider enhancement** — Add grouping, filtering, price total to `shopping_items_provider.dart`
2. **Duplicate warning** — Add client-side check in `add_item_usecase.dart`
3. **Autocomplete** — Enhance `item_suggestions_widget.dart` with name+qty+unit display
4. **Template sync** — Ensure `add_item_usecase.dart` syncs templates, `update_item_usecase.dart` does not
5. **Category grouping** — Update `shopping_list_detail_screen.dart` with collapsible headers
6. **Search & filter** — Add search bar and category filter to detail screen
7. **Quick Add** — Enhance `quick_add_screen.dart` with usage count sorting
8. **Price total** — Add unpurchased total display to detail screen
9. **Undo delete** — Add 5-second undo snackbar to `delete_item_usecase.dart`

## Testing

```bash
# Run unit tests
flutter test test/unit/features/shopping_lists/

# Run widget tests
flutter test test/widget/features/shopping_lists/

# Run full test suite
flutter test

# Check for analysis issues
flutter analyze
```
