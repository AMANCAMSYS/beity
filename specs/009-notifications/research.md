# Research: Notifications

**Feature**: 009-notifications
**Date**: 2026-05-13
**Status**: Complete

## Research Tasks

### 1. Notification Delivery Architecture

**Decision**: Firebase FCM via Supabase Edge Functions with database triggers
**Rationale**:
- FCM already integrated in project (`notification_service.dart`)
- Edge Functions can be triggered by PostgreSQL changes via `pg_net` or invoked from client
- Keeps notification logic server-side for reliability (FR-013)
- Supports both foreground and background delivery

**Alternatives Considered**:
- Client-side only notifications: Won't work when app is closed or user is offline
- Supabase Webhooks: Less flexible than Edge Functions for complex logic
- OneSignal/Pushwoosh: Additional third-party dependency, FCM already configured

**Implementation Flow**:
1. Database trigger fires on shopping_items/invitations/home_members INSERT/UPDATE
2. Trigger calls Edge Function via `pg_net` or Supabase function call
3. Edge Function checks notification preferences, throttling, and builds message
4. Edge Function sends FCM notification to target user's device tokens
5. Edge Function inserts record into `notifications` table for history

### 2. Notification Throttling & Batching Strategy

**Decision**: Server-side batching with 2-minute window per user per home
**Rationale**:
- Per clarification: 2-minute default window
- Server-side ensures consistency even with multiple clients
- Batch by user+home to group related activity

**Alternatives Considered**:
- Client-side throttling: Inconsistent across devices, fails when app is closed
- FCM topic-based throttling: No built-in batching support
- No batching: Would spam users during active shopping sessions

**Implementation Approach**:
1. Edge Function checks `notifications` table for recent entries (last 2 min) for same user+home
2. If recent notification exists, update it with aggregated summary instead of creating new one
3. Summary format: "Ahmed added 5 items to Grocery List" instead of 5 separate notifications
4. FCM data message sent with updated content; local notification refreshed

### 3. Notification Storage & Retention

**Decision**: Store in Supabase PostgreSQL with 30-day auto-deletion
**Rationale**:
- Per clarification: 30-day retention
- PostgreSQL allows efficient querying with indexes
- Cron job or pg_cron to delete expired notifications
- Consistent with existing Supabase backend

**Alternatives Considered**:
- Firebase Firestore: Would require dual database, adds complexity
- Redis/TTL-based store: Additional infrastructure, not in tech stack
- Client-only storage: Lost on app reinstall, no cross-device sync

**Implementation Details**:
- `notifications` table with `created_at` timestamp
- Scheduled function or pg_cron job runs daily to delete records older than 30 days
- Index on (user_id, created_at) for efficient history queries

### 4. Notification Suppression for Active Screens

**Decision**: Track active screen subscription on client, suppress display locally
**Rationale**:
- Per FR-004: suppress when user is viewing the relevant screen
- Real-time subscription already provides live updates
- Notification still recorded in history (per clarification: all events shown)

**Alternatives Considered**:
- Server-side suppression: Requires tracking client state server-side, complex
- No suppression: Annoying duplicate alerts when already viewing
- FCM collapse keys: Limited control, not suitable for all scenarios

**Implementation Approach**:
1. Client maintains set of active screen subscriptions (e.g., `shopping_list:{listId}`)
2. When FCM message arrives while screen is active, skip local notification display
3. Still insert into `notifications` table (server-side, always happens)
4. Notification center shows all events regardless of suppression

### 5. Deep Linking from Notifications

**Decision**: GoRouter deep links with notification payload containing route information
**Rationale**:
- GoRouter already used for routing in the project
- Supports named routes and path parameters
- Works from both foreground and background notification taps

**Alternatives Considered**:
- Custom URL scheme: More complex, GoRouter already handles this
- No deep linking: Poor UX, user has to navigate manually
- Firebase Dynamic Links: Deprecated service

**Implementation Details**:
- FCM data payload includes `route` field (e.g., `/shopping-lists/{id}`)
- `NotificationService._handleNotificationTap` parses payload and navigates via GoRouter
- Background handler stores pending navigation, applied on app resume

### 6. Notification Preferences Storage

**Decision**: Per-user per-category preferences in dedicated table
**Rationale**:
- Per clarification: Users toggle categories (shopping list, home activity, invitations)
- Simple boolean toggle per category
- Checked server-side before sending

**Alternatives Considered**:
- JSON column on user profile: Less queryable, harder to enforce
- FCM topic subscriptions: Doesn't persist across devices, limited control
- No preferences: All or nothing, poor UX

**Implementation Details**:
- `notification_preferences` table with (user_id, category, enabled)
- Default: all categories enabled for new users
- Edge Function queries preferences before sending
- Client updates preferences via Supabase client

### 7. Arabic RTL Notification Content

**Decision**: Server-side bilingual content generation with locale preference
**Rationale**:
- Per clarification: Arabic and English from day one
- Notification body generated server-side for consistency
- User locale stored in profile, used to select language

**Alternatives Considered**:
- Client-side translation: Requires both language strings in payload, doubles size
- Single language: Rejected per spec requirement
- External translation service: Over-engineered for templated messages

**Implementation Details**:
- Edge Function uses user's locale preference to generate notification text
- Templates stored in both Arabic and English
- FCM payload includes pre-rendered title and body in correct language
- RTL display handled by OS natively for push notifications

### 8. Device Token Management

**Decision**: Reuse existing `device_tokens` table and `NotificationService`
**Rationale**:
- Already implemented in `notification_service.dart`
- Table stores user_id, token, platform
- Token refresh already handled

**Alternatives Considered**:
- New table: Unnecessary, existing table covers needs
- FCM topic-based: Less granular control, doesn't support per-user preferences

**Implementation Details**:
- Existing `device_tokens` table with RLS
- Edge Function queries tokens for target user_id
- Handles multiple devices per user (send to all)
- Cleanup stale tokens on delivery failure (FCM error code `messaging/registration-token-not-registered`)

## Summary

All research tasks completed. Key decisions:
1. FCM via Supabase Edge Functions for reliable delivery
2. Server-side 2-minute batching to prevent spam
3. PostgreSQL storage with 30-day retention
4. Client-side suppression for active screens
5. GoRouter deep links for notification navigation
6. Per-user category preferences with server-side enforcement
7. Server-side bilingual content (Arabic/English)
8. Reuse existing device_tokens infrastructure

No blocking unknowns remain. Ready for Phase 1 design.
