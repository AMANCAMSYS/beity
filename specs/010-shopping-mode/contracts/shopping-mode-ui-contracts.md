# UI Contracts: Shopping Mode

**Feature**: 010-shopping-mode  
**Date**: 2026-05-13

## Screen: ShoppingModeScreen

**Route**: `/shopping-lists/:listId/shopping-mode`  
**Entry Point**: "Start Shopping" button on ShoppingListScreen

### Layout

```
┌─────────────────────────────────────┐
│  [Progress Bar]        [Search] [X] │  ← App bar (minimal)
├─────────────────────────────────────┤
│  ▼ Dairy (3/5)                     │  ← Category header (collapsible)
│  ┌─────────────────────────────┐   │
│  │ 🥛 Milk          2L    [✓] │   │  ← Item card (tap to purchase)
│  │ 🧀 Cheese        1kg   [✓] │   │
│  │ 🥛 Yogurt        500g      │   │  ← Unpurchased (bold)
│  └─────────────────────────────┘   │
│  ▼ Produce (0/3)                   │  ← Category header
│  ┌─────────────────────────────┐   │
│  │ 🍎 Apples        1kg       │   │
│  │ 🥕 Carrots       500g      │   │
│  └─────────────────────────────┘   │
│  ▶ Cleaning (2/2) ✓               │  ← Completed category (collapsed)
│                                     │
│                              [+]    │  ← Floating add button
├─────────────────────────────────────┤
│  [Done Shopping]                    │  ← Bottom bar
└─────────────────────────────────────┘
```

### Widgets

#### ShoppingItemCard

| Property | Type | Description |
|----------|------|-------------|
| item | ShoppingItem | The item to display |
| onTap | VoidCallback | Toggle purchased state |
| onQuantityTap | VoidCallback | Show quantity controls |
| isPurchased | bool | Visual state |

**Behavior**:
- Tap anywhere → toggle purchased
- Tap quantity → show inline +/- controls
- Purchased state: strikethrough name, muted color, moves to category bottom

**Visual Specs**:
- Height: 72dp (large touch target)
- Border radius: 12dp
- Background: surface color, elevated 1dp
- Purchased: 50% opacity, strikethrough text
- RTL: Text right-aligned, icons mirrored

#### ShoppingCategoryGroup

| Property | Type | Description |
|----------|------|-------------|
| category | Category | Category info |
| items | List<ShoppingItem> | Items in this category |
| isCollapsed | bool | Collapsed state |
| onToggle | VoidCallback | Toggle collapse |

**Behavior**:
- Tap header → toggle collapse
- Auto-collapse when all items purchased
- Shows checkmark when all items purchased
- "Other" group for uncategorized items

**Visual Specs**:
- Header height: 48dp
- Header font: title medium, bold
- Collapse icon: chevron (direction-aware for RTL)
- Completed indicator: ✓ icon

#### ShoppingProgressBar

| Property | Type | Description |
|----------|------|-------------|
| purchasedCount | int | Items marked purchased |
| totalCount | int | Total items in list |

**Behavior**:
- Shows progress bar + text (e.g., "12 of 20 items purchased")
- Updates in real-time as items are marked
- Shows completion message when all items purchased

**Visual Specs**:
- Height: 56dp
- Progress bar: linear, rounded ends
- Text: body large
- Color: primary when in progress, success when complete

#### ShoppingQuickAddOverlay

| Property | Type | Description |
|----------|------|-------------|
| listId | String | Target shopping list |
| onItemAdded | VoidCallback | Callback after item added |
| onClose | VoidCallback | Close overlay |

**Behavior**:
- Bottom sheet with large text field
- Autocomplete from templates and previous items
- "Add" button submits and clears field
- "Add Another" checkbox keeps overlay open
- Swipe down to dismiss

**Visual Specs**:
- Text field height: 56dp
- Font size: 18sp (large for quick typing)
- Border radius: 16dp (top corners)
- Autocomplete: max 5 suggestions

#### ShoppingQuantityControls

| Property | Type | Description |
|----------|------|-------------|
| quantity | double | Current quantity |
| unit | String | Unit of measurement |
| onChanged | ValueChanged<double> | Quantity change callback |

**Behavior**:
- Inline +/- buttons
- Tap + → increment by 1
- Tap - → decrement by 1 (min 1)
- Long press → rapid change
- Syncs in real-time

**Visual Specs**:
- Button size: 40dp
- Font: title medium
- Spacing: 8dp between buttons and value

#### ShoppingExitSummary

| Property | Type | Description |
|----------|------|-------------|
| session | ShoppingModeSession | Session data |
| purchasedItems | List<ShoppingItem> | Items purchased |
| onDismiss | VoidCallback | Close summary |

**Behavior**:
- Bottom sheet showing session summary
- Count: "15 of 20 items purchased"
- List of purchased items grouped by category
- Each item shows who purchased it
- "Return to List" button

**Visual Specs**:
- Max height: 60% of screen
- Scrollable content
- Category headers: same as ShoppingCategoryGroup
- Purchaser name: caption text, muted

#### ShoppingModeSearchBar

| Property | Type | Description |
|----------|------|-------------|
| onChanged | ValueChanged<String> | Search query callback |
| onClear | VoidCallback | Clear search |

**Behavior**:
- Inline at top of list (below app bar)
- Real-time filtering as user types
- Searches item names only
- Clear button resets filter
- Hides category groups with no matching items

**Visual Specs**:
- Height: 48dp
- Rounded corners
- Search icon left-aligned (RTL-aware)
- Clear icon when text present

## State Management

### ShoppingModeProvider

```dart
@riverpod
class ShoppingMode extends _$ShoppingMode {
  // Manages shopping mode state
  // - isActive: bool
  // - sessionId: String?
  // - searchQuery: String
  // - collapsedCategories: Set<String>
}
```

### ShoppingModeItemsProvider

```dart
@riverpod
class ShoppingModeItems extends _$ShoppingModeItems {
  // Provides filtered and grouped items
  // - List of (Category, List<ShoppingItem>) pairs
  // - Filters by search query
  // - Sorts: unpurchased first within category, purchased at bottom
}
```

### ShoppingModeSessionProvider

```dart
@riverpod
class ShoppingModeSession extends _$ShoppingModeSession {
  // Manages session lifecycle
  // - startSession(listId)
  // - endSession()
  // - incrementPurchasedCount()
}
```

## Real-Time Subscriptions

Shopping mode subscribes to:
- `shopping_items` changes for the current list (INSERT, UPDATE, DELETE)
- Updates item list and progress bar in real-time
- Handles concurrent edits from other shoppers

## Screen Keep-Awake

```dart
// On enter shopping mode
await WakelockPlus.enable();

// On exit shopping mode
await WakelockPlus.disable();
```

## Navigation

- Enter: Push `/shopping-lists/:listId/shopping-mode`
- Exit: Pop with confirmation if unpurchased items remain
- Back button: Same as exit (with confirmation)
