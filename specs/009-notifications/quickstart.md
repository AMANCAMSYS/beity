# Quickstart: Notifications

**Feature**: 009-notifications
**Date**: 2026-05-13
**Status**: Complete

## Overview

This quickstart guide helps you get started with the Notifications feature implementation. Notifications enable push alerts for shopping list changes, home activity, and invitations, with a notification center for history.

## Prerequisites

1. Completed specs 001-008 (Auth, Homes, Invitations, Categories, Shopping Lists, Shopping Items, Realtime Sync, Activity Logs)
2. Supabase project configured with existing tables
3. Firebase project configured with FCM
4. Flutter development environment set up
5. `notification_service.dart` already exists in `lib/core/services/`

## Setup Steps

### 1. Database Migration

Run the migration to create notification tables:

```bash
supabase migration up
```

This creates:
- `notifications` table with RLS policies
- `notification_preferences` table with RLS policies
- Indexes for performance
- pg_cron job for 30-day cleanup
- Database triggers for notification generation

### 2. Deploy Edge Functions

Deploy the notification Edge Functions:

```bash
supabase functions deploy send-notification
supabase functions deploy get-notification-history
supabase functions deploy mark-notifications-read
supabase functions deploy update-notification-preferences
supabase functions deploy cleanup-old-notifications
```

### 3. Create Feature Directory Structure

```bash
mkdir -p lib/features/notifications/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}
```

### 4. Implement Data Layer

Start with models and repositories:

1. **Models**: Create Dart classes matching database schema
   - `notification_model.dart`
   - `notification_preference_model.dart`

2. **Repositories**: Implement Supabase operations
   - `notification_repository.dart` (interface)
   - `supabase_notification_repository.dart` (implementation)

### 5. Implement Domain Layer

Create entities and use cases:

1. **Entities**: Business objects
   - `notification.dart`
   - `notification_preference.dart`

2. **Use Cases**: Business logic operations
   - `get_notification_history_usecase.dart`
   - `mark_notifications_read_usecase.dart`
   - `update_notification_preferences_usecase.dart`
   - `get_unread_count_usecase.dart`

### 6. Implement Presentation Layer

Build UI components:

1. **Providers**: Riverpod state management
   - `notifications_provider.dart` — notification history with pagination
   - `notification_preferences_provider.dart` — user preferences
   - `unread_count_provider.dart` — badge count

2. **Screens**: Main UI screens
   - `notification_center_screen.dart` — notification history list
   - `notification_preferences_screen.dart` — toggle categories

3. **Widgets**: Reusable UI components
   - `notification_tile_widget.dart` — single notification row
   - `notification_badge_widget.dart` — unread count badge
   - `notification_preference_toggle.dart` — category toggle

### 7. Update NotificationService

Extend `lib/core/services/notification_service.dart`:

1. Add notification tap handler with GoRouter deep linking
2. Add foreground notification display with flutter_local_notifications
3. Add active screen tracking for suppression logic
4. Add notification history sync on app launch

### 8. Wire Up Navigation

Add notification center entry point:

1. Add notification bell icon with badge to home screen
2. Navigate to `notification_center_screen` on tap
3. Handle deep links from notification taps

## Testing

### Unit Tests

```bash
flutter test test/unit/features/notifications/
```

Test coverage should include:
- Repositories (mock Supabase client)
- Use cases (mock repositories)
- Notification content generation (Arabic/English)
- Throttling logic

### Widget Tests

```bash
flutter test test/widget/features/notifications/
```

Test coverage should include:
- Notification center screen
- Notification tile widget
- Preference toggles
- Unread badge

### Integration Tests

```bash
flutter test test/integration/features/notifications/
```

Test coverage should include:
- Full notification flow (event → Edge Function → FCM → display)
- Notification preferences toggle → verify suppression
- Deep link navigation from notification tap
- 30-day cleanup verification

## Common Patterns

### Listening for Unread Count

```dart
final unreadCount = ref.watch(unreadCountProvider);
// Shows badge on notification bell icon
```

### Toggling a Notification Preference

```dart
final updatePrefs = ref.read(updateNotificationPreferencesUseCaseProvider);
await updatePrefs(category: 'shopping_list', enabled: false);
```

### Handling Notification Tap

```dart
// In NotificationService._handleNotificationTap
void _handleNotificationTap(RemoteMessage message) {
  final route = message.data['route'];
  if (route != null) {
    GoRouter.of(navigatorKey.currentContext!).go(route);
  }
}
```

### Suppressing Notifications for Active Screen

```dart
// In notification handler
final activeScreens = ref.read(activeScreenSubscriptionProvider);
final targetRoute = message.data['route'];
if (activeScreens.contains(targetRoute)) {
  // Skip local notification, but still record in history
  return;
}
```

## Troubleshooting

### Notifications not received
- Verify FCM token is registered in `device_tokens` table
- Check Edge Function logs in Supabase dashboard
- Ensure notification preferences are enabled for the category
- Verify database trigger is firing (check pg_net logs)

### Notification history empty
- Check RLS policies allow SELECT for the user
- Verify Edge Function `get-notification-history` is deployed
- Check that `notifications` table has data

### Deep links not working
- Verify GoRouter route is registered
- Check FCM data payload includes `route` field
- Ensure `_handleNotificationTap` is registered in `NotificationService`

### Arabic text not displaying correctly
- Check user locale preference is stored correctly
- Verify Edge Function generates Arabic content for Arabic locale
- Ensure FCM payload includes correct `title` and `body` in Arabic

## Next Steps

After completing the basic implementation:
1. Add notification grouping by home in the notification center
2. Implement pull-to-refresh for notification history
3. Add "mark all as read" functionality
4. Optimize for large notification histories (virtual scrolling)
5. Add notification sound/vibration customization
