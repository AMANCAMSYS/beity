# Quickstart: Realtime Sync

**Date**: 2026-05-13
**Feature**: 007-realtime-sync

## Prerequisites

- Flutter SDK installed
- Supabase project configured (URL + anon key in `.env`)
- App running on a physical device (realtime requires network)

## Key Concepts

1. **Postgres Changes**: Supabase streams database changes to connected clients via `.stream(primaryKey:)`. Already used for shopping_items and shopping_lists.

2. **Presence**: Ephemeral user tracking on scoped channels. Users join when viewing a list, leave when navigating away.

3. **Connection State**: Network + server connectivity detection. Shows "Disconnected" / "Syncing..." indicators.

4. **Offline Queue**: In-memory list of mutations made while offline. Executed on reconnect, discarded on logout.

## What's New (not in existing code)

| Component | Location | Purpose |
|-----------|----------|---------|
| `RealtimeService` | `lib/core/services/realtime_service.dart` | Shared service for presence, connection state, missed-changes fetch |
| `ConnectionStatusWidget` | `lib/features/shopping_lists/presentation/widgets/connection_status_widget.dart` | "Disconnected" banner + "Syncing..." progress bar |
| `PresenceIndicatorWidget` | `lib/features/shopping_lists/presentation/widgets/presence_indicator_widget.dart` | Avatar row showing who's viewing the list |
| `ItemUpdatedToast` | `lib/features/shopping_lists/presentation/widgets/item_updated_toast.dart` | Toast for conflict notification |

## What's Modified

| Component | Change |
|-----------|--------|
| `shopping_items_provider.dart` | Add presence provider, connection state provider, conflict detection |
| `shopping_lists_provider.dart` | Add home-level realtime streams for members/categories |
| `supabase_shopping_list_repository.dart` | Add presence tracking alongside existing `.stream()` calls |
| `shopping_list_detail_screen.dart` | Integrate presence indicator, connection status, conflict toast |
| `shopping_lists_screen.dart` | Integrate removed member redirect detection |

## Testing

1. **Presence**: Open same list on 2 devices → verify avatars appear on both
2. **Connection**: Enable airplane mode → verify "Disconnected" banner → disable → verify "Syncing..." → verify items sync
3. **Conflict**: Edit same item on 2 devices simultaneously → verify toast + highlight on overwritten device
4. **Removed member**: Remove user from home on device A → verify dialog + redirect on device B
5. **Offline queue**: Go offline → add item → go online → verify item syncs

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| supabase_flutter | ^2.8.4 | Already installed. Provides `.stream()`, Presence, channel management |
| connectivity_plus | ^6.0.0 | NEW: Network state detection |
| flutter_riverpod | (existing) | State management for realtime providers |
