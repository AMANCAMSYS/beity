# Research: Shopping Lists

**Feature**: 005-shopping-lists  
**Date**: 2026-05-12  
**Status**: Complete

## Research Tasks

### 1. Real-time Collaboration Pattern

**Decision**: Use Supabase Realtime with PostgreSQL changes  
**Rationale**: 
- Already integrated in the project (Supabase Flutter)
- Supports row-level changes for shopping_items table
- Built-in conflict resolution via updated_at timestamp
- No additional infrastructure needed

**Alternatives Considered**:
- WebSocket custom implementation: More complex, requires own server
- Firebase Realtime Database: Would require dual backend (Supabase + Firebase)
- Polling: Not real-time, higher server load

**Implementation Pattern**:
```dart
// Subscribe to shopping_items changes
supabase
  .from('shopping_items')
  .stream(primaryKey: ['id'])
  .eq('shopping_list_id', listId)
  .listen((List<Map<String, dynamic>> data) {
    // Update local state
  });
```

### 2. Offline Support Strategy

**Decision**: Basic offline with local caching + auto-sync  
**Rationale**:
- Aligns with clarification: "view and edit locally, auto-sync when reconnected"
- Isar mentioned in tech stack for offline support
- Keep MVP simple - no complex conflict resolution

**Alternatives Considered**:
- No offline (remove FR-011): Rejected per clarification
- Full offline with CRDTs: Too complex for MVP
- SQLite: Heavier than Isar for Flutter

**Implementation Approach**:
1. Cache shopping lists and items in Isar
2. Queue mutations when offline
3. Sync queue when connection restored
4. Use last-write-wins for conflicts (per clarification)

### 3. Notification Strategy

**Decision**: Firebase FCM with Supabase Edge Functions  
**Rationale**:
- FCM already integrated in project
- Edge Functions can trigger on database changes
- Reuse existing notification_service.dart

**Alternatives Considered**:
- Supabase Webhooks: Less flexible
- Client-side only notifications: Won't work when app is closed
- OneSignal: Additional dependency

**Implementation Flow**:
1. Database trigger on shopping_items INSERT/UPDATE
2. Edge Function sends FCM notification
3. Exclude actor from notification (per clarification)
4. Notification includes list name and item details

### 4. Item Suggestions Algorithm

**Decision**: Frequency-based suggestions from purchase history  
**Rationale**:
- Simple and effective for recurring shopping needs
- Uses existing data (purchased items)
- No external API dependency

**Alternatives Considered**:
- Machine learning suggestions: Over-engineered for MVP
- External product API: Additional dependency
- Manual favorites only: Less useful

**Implementation Approach**:
1. Track item name and usage count in item_templates table
2. Increment count when item is purchased
3. Suggest top N items by usage count
4. Filter by current home's categories

### 5. Price Tracking Implementation

**Decision**: Optional price field with currency support  
**Rationale**:
- Per clarification: "Optional price field on items"
- Support multiple currencies (future-proof)
- Nullable field for items without price

**Alternatives Considered**:
- Required price field: Too restrictive
- Price history: Over-engineered for MVP
- No price tracking: Rejected per clarification

**Implementation Details**:
- Add `price` (DECIMAL) and `currency` (VARCHAR) to shopping_items
- Default currency from home settings
- Summary shows total for items with prices

### 6. Concurrent Edit Resolution

**Decision**: Last-write-wins based on updated_at  
**Rationale**:
- Per clarification: "Last-write-wins - latest edit overwrites previous"
- Simple to implement
- No conflict UI needed
- Supabase handles timestamp updates

**Alternatives Considered**:
- Operational transformation: Too complex
- CRDTs: Over-engineered
- First-write-wins: Poor UX for shopping lists

**Implementation Details**:
- All updates set `updated_at = NOW()`
- Real-time subscription receives latest state
- Client always shows latest received data

### 7. List Deletion Permissions

**Decision**: Creator + Home owner/admin can delete  
**Rationale**:
- Per clarification: "List creator and home owner/admin can delete"
- Aligns with existing role system
- Prevents accidental deletion by regular members

**Implementation Details**:
- Check user role in home_members table
- Check if user is list creator
- Allow delete if either condition is true

### 8. Arabic RTL Support

**Decision**: Flutter's built-in RTL support with Directionality widget  
**Rationale**:
- Already implemented in previous specs
- Flutter handles RTL automatically with Directionality
- Bilingual text helper already exists

**Implementation Details**:
- Use `Directionality` widget based on locale
- All layouts use `Row`/`Column` (auto-flip)
- Text alignment follows direction
- Icons that imply direction are mirrored

## Summary

All research tasks completed. Key decisions:
1. Supabase Realtime for live updates
2. Isar for basic offline caching
3. FCM via Edge Functions for notifications
4. Frequency-based item suggestions
5. Optional price tracking with currency
6. Last-write-wins for concurrent edits
7. Role-based deletion permissions
8. Flutter RTL support (existing pattern)

No blocking unknowns remain. Ready for Phase 1 design.
