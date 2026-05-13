# Research: Shopping Mode

**Feature**: 010-shopping-mode  
**Date**: 2026-05-13

## Research Tasks

### 1. Screen Keep-Awake Implementation

**Decision**: Use `wakelock_plus` package  
**Rationale**: 
- Most popular and maintained Flutter package for screen keep-awake
- Supports both iOS and Android with platform-specific APIs
- Simple API: `WakelockPlus.enable()` / `WakelockPlus.disable()`
- No additional permissions required on either platform

**Alternatives considered**:
- `screen` package: Less maintained, fewer downloads
- `keep_screen_on` package: Similar functionality but smaller community
- Platform channels: Unnecessary complexity when a package exists

### 2. Shopping Mode Session Persistence

**Decision**: New `shopping_mode_sessions` table in Supabase PostgreSQL  
**Rationale**:
- Enables shopping history and analytics (per spec clarification)
- Simple schema: list_id, user_id, home_id, started_at, ended_at, counters
- RLS via home membership (same pattern as other tables)
- Minimal storage overhead (one row per session)

**Alternatives considered**:
- Local-only storage (Isar/Hive): Loses cross-device history, no analytics
- Embedding session data in shopping_lists table: Adds complexity to existing table
- Supabase Realtime presence: Ephemeral, doesn't persist history

### 3. Real-Time Sync for Concurrent Shoppers

**Decision**: Reuse existing Supabase Realtime subscriptions from SPEC 007  
**Rationale**:
- Shopping mode operates on the same `shopping_items` table
- Existing Realtime subscription infrastructure handles INSERT/UPDATE/DELETE
- Multiple simultaneous sessions already supported by the architecture
- No new Realtime channels needed

**Alternatives considered**:
- Separate Realtime channel for shopping mode: Unnecessary duplication
- Polling: Too slow for real-time feel, higher battery usage
- WebSocket custom implementation: Reinventing what Supabase provides

### 4. Category Grouping Strategy

**Decision**: Group by existing `category_id` on shopping_items, with "Other" for uncategorized  
**Rationale**:
- Categories from SPEC 004 already exist and are assigned to items
- Collapsible headers per category with auto-collapse when all items purchased
- "Other" group at end for items without category
- Sort order: categories by name, items within category by added_at

**Alternatives considered**:
- Store-specific aisle mapping: Out of scope per spec, requires store data
- Custom sort order: Adds complexity, users can reorder manually later
- Flat list with category badges: Loses the aisle-by-aisle shopping benefit

### 5. Purchased Items Placement

**Decision**: Purchased items sink to bottom of their category group  
**Rationale**:
- Per spec clarification, users want to see what's done per section
- Avoids scrolling away from current category to find purchased items
- Completed categories auto-collapse with checkmark indicator
- Visual distinction: strikethrough + muted color for purchased items

**Alternatives considered**:
- Separate "Purchased" section at bottom: Breaks category-based shopping flow
- Toggle between views: Adds UI complexity, unclear value
- Hide purchased entirely: Users lose track of what was bought

### 6. Quick-Add Overlay Design

**Decision**: Bottom sheet overlay with large text field, autocomplete, and "Add Another" option  
**Rationale**:
- Bottom sheet is thumb-friendly for one-handed use
- Large text field optimized for quick typing
- Autocomplete from item templates and previous items
- "Add Another" checkbox keeps overlay open for consecutive additions
- Minimal fields: name only by default, quantity/unit from template if matched

**Alternatives considered**:
- Full-screen modal: Too heavy for quick add
- Inline add at bottom of list: Harder to see with long lists
- Floating text field: Less discoverable, smaller touch target

### 7. Exit Summary Content

**Decision**: Bottom sheet with count, purchased items list by category, and purchaser attribution  
**Rationale**:
- Per spec clarification: count + list + who purchased what
- Grouped by category for easy review
- Shows purchaser name next to each item
- "Return to List" button to exit

**Alternatives considered**:
- Simple dialog: Too small for detailed summary
- Full-screen summary: Overkill for exit flow
- No summary: Users lose context of what was accomplished

### 8. Search in Shopping Mode

**Decision**: Inline search bar at top, filters visible items in real-time  
**Rationale**:
- Standard pattern for list filtering
- Real-time filtering as user types
- Searches item names only (not categories)
- Clear button to reset search
- Works with category grouping (filters within groups)

**Alternatives considered**:
- Search icon that opens modal: Extra tap, slower
- Category-only filter: Doesn't help find specific items
- Global search across lists: Out of scope for shopping mode

## Unresolved Items

All research questions resolved. No NEEDS CLARIFICATION markers remain.
