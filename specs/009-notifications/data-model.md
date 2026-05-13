# Data Model: Notifications

**Feature**: 009-notifications
**Date**: 2026-05-13
**Status**: Complete

## Entities

### 1. notifications

Represents a single notification sent to a user. Retained for 30 days, then auto-deleted.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| user_id | UUID | NO | - | Recipient (foreign key to auth.users) |
| home_id | UUID | NO | - | Related home (foreign key to homes) |
| category | VARCHAR(50) | NO | - | Notification category (shopping_list, home_activity, invitation) |
| type | VARCHAR(50) | NO | - | Specific event type (item_added, item_completed, item_updated, member_joined, invitation_received) |
| title | VARCHAR(255) | NO | - | Notification title (localized) |
| body | TEXT | NO | - | Notification body (localized) |
| actor_id | UUID | YES | NULL | User who triggered the event (foreign key to auth.users) |
| target_route | VARCHAR(255) | YES | NULL | Deep link route (e.g., /shopping-lists/{id}) |
| reference_id | UUID | YES | NULL | ID of related entity (shopping_list_id, invitation_id, etc.) |
| reference_type | VARCHAR(50) | YES | NULL | Type of related entity (shopping_list, invitation, home) |
| is_read | BOOLEAN | NO | FALSE | Whether user has read/interacted with this notification |
| batch_key | VARCHAR(255) | YES | NULL | Throttle key: `{user_id}:{home_id}:{category}` |
| created_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Notification creation timestamp |

**Constraints**:
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
- FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
- FOREIGN KEY (actor_id) REFERENCES auth.users(id) ON DELETE SET NULL
- CHECK (category IN ('shopping_list', 'home_activity', 'invitation'))

**Indexes**:
- idx_notifications_user_id ON (user_id, created_at DESC) — history queries
- idx_notifications_unread ON (user_id, is_read) WHERE is_read = FALSE — unread badge count
- idx_notifications_batch ON (batch_key, created_at DESC) — throttling lookup
- idx_notifications_home ON (user_id, home_id, created_at DESC) — per-home filtering

**RLS Policies**:
```sql
-- Users can only see their own notifications
CREATE POLICY "Users can view own notifications"
ON notifications FOR SELECT
USING (user_id = auth.uid());

-- Only server/service role can insert notifications
CREATE POLICY "Service can insert notifications"
ON notifications FOR INSERT
WITH CHECK (TRUE); -- Restricted to service role via Edge Function

-- Users can mark their own notifications as read
CREATE POLICY "Users can update own notifications"
ON notifications FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
ON notifications FOR DELETE
USING (user_id = auth.uid());
```

**Triggers**:
```sql
-- Auto-update is_read when user interacts
-- (Handled by application logic, no trigger needed)
```

**Scheduled Cleanup**:
```sql
-- pg_cron job to delete notifications older than 30 days
-- Runs daily at 03:00 UTC
SELECT cron.schedule(
  'delete-old-notifications',
  '0 3 * * *',
  $$DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '30 days'$$
);
```

---

### 2. notification_preferences

Represents a user's notification settings per category.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| user_id | UUID | NO | - | Foreign key to auth.users |
| category | VARCHAR(50) | NO | - | Notification category (shopping_list, home_activity, invitation) |
| enabled | BOOLEAN | NO | TRUE | Whether notifications are enabled for this category |
| created_by | UUID | NO | auth.uid() | Foreign key to auth.users |
| created_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Creation timestamp |
| updated_at | TIMESTAMP WITH TIME ZONE | NO | NOW() | Last update timestamp |

**Constraints**:
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
- FOREIGN KEY (created_by) REFERENCES auth.users(id)
- UNIQUE (user_id, category) — one preference per category per user
- CHECK (category IN ('shopping_list', 'home_activity', 'invitation'))

**Indexes**:
- idx_notification_preferences_user ON (user_id) — lookup by user
- idx_notification_preferences_lookup ON (user_id, category, enabled) — Edge Function query

**RLS Policies**:
```sql
-- Users can view their own preferences
CREATE POLICY "Users can view own notification preferences"
ON notification_preferences FOR SELECT
USING (user_id = auth.uid());

-- Users can insert their own preferences
CREATE POLICY "Users can insert own notification preferences"
ON notification_preferences FOR INSERT
WITH CHECK (user_id = auth.uid() AND created_by = auth.uid());

-- Users can update their own preferences
CREATE POLICY "Users can update own notification preferences"
ON notification_preferences FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

**Triggers**:
```sql
-- Auto-update updated_at on changes
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON notification_preferences
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);
```

**Default Preferences**:
```sql
-- Insert default preferences for new users (all categories enabled)
-- Triggered after user signup or handled by Edge Function
INSERT INTO notification_preferences (user_id, category, enabled)
VALUES
  (NEW_USER_ID, 'shopping_list', TRUE),
  (NEW_USER_ID, 'home_activity', TRUE),
  (NEW_USER_ID, 'invitation', TRUE);
```

---

## Entity Relationships

```
auth.users (1) ──── (N) notifications
    │                     │
    │                     ├── (N) ──── (1) homes
    │                     │
    │                     └── (N) ──── (1) auth.users (actor_id)
    │
    └── (1) ──── (N) notification_preferences
```

## State Transitions

### Notification Read State
```
unread ──────► read
```

- **unread**: Default state, notification delivered but not interacted with
- **read**: User has tapped or viewed the notification (is_read = TRUE)

### Notification Preference State
```
enabled ◄───► disabled
```

- **enabled**: Default state, notifications are delivered for this category
- **disabled**: User has opted out, notifications are suppressed for this category

## Data Volume Assumptions

- Average 5-10 notifications per user per day during active use
- Up to 100 notifications retained per user (30 days × ~3/day)
- 3 preference rows per user (one per category)
- Multiple devices per user (device_tokens table already exists)

## Migration Strategy

1. Create `notification_preferences` table first (no dependencies beyond auth.users)
2. Create `notifications` table with foreign keys to homes and auth.users
3. Enable RLS on both tables
4. Create indexes for performance
5. Set up pg_cron job for 30-day cleanup
6. Seed default preferences for existing users
