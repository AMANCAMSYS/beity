# Edge Function Contracts: Notifications

**Feature**: 009-notifications
**Date**: 2026-05-13
**Status**: Complete

## Overview

Notification delivery is handled by Supabase Edge Functions invoked by database triggers. The functions are responsible for checking preferences, throttling, generating localized content, sending FCM messages, and recording notification history.

---

## Function: `send-notification`

### Purpose
Send a notification to one or more users in response to a home event (shopping list change, membership change, invitation).

### Trigger
Called by PostgreSQL trigger via `pg_net` or by application code via Supabase client.

### Request

```json
{
  "event_type": "item_added | item_completed | item_updated | member_joined | invitation_received",
  "home_id": "uuid",
  "actor_id": "uuid",
  "reference_id": "uuid",
  "reference_type": "shopping_list | invitation | home",
  "context": {
    "item_name": "Milk",
    "list_name": "Grocery List",
    "home_name": "My Home",
    "member_name": "Ahmed"
  }
}
```

### Processing Logic

1. **Resolve recipients**: Query `home_members` for `home_id`, exclude `actor_id`
2. **Check preferences**: For each recipient, query `notification_preferences` for the relevant category. Skip if `enabled = FALSE`
3. **Check throttling**: Query `notifications` for recent entries (last 2 minutes) matching `batch_key` (user_id + home_id + category)
   - If recent batch exists: update existing notification with aggregated summary
   - If no recent batch: create new notification
4. **Generate content**: Build localized title/body based on `event_type` and `context`, using recipient's locale preference
5. **Record notification**: Insert into `notifications` table
6. **Send FCM**: Query `device_tokens` for each recipient, send FCM data message to all tokens

### Response

```json
{
  "success": true,
  "notifications_sent": 3,
  "notifications_batched": 1,
  "recipients": ["user_id_1", "user_id_2", "user_id_3"]
}
```

### Error Responses

| Status | Code | Description |
|--------|------|-------------|
| 400 | INVALID_EVENT_TYPE | Event type not recognized |
| 400 | MISSING_REQUIRED_FIELD | Required field missing from request |
| 404 | HOME_NOT_FOUND | Home ID does not exist |
| 500 | INTERNAL_ERROR | Unexpected server error |

---

## Function: `get-notification-history`

### Purpose
Retrieve paginated notification history for the authenticated user.

### Trigger
Called by Flutter client via Supabase client.

### Request

```json
{
  "limit": 20,
  "offset": 0,
  "home_id": "uuid (optional filter)",
  "category": "string (optional filter)",
  "unread_only": false
}
```

### Processing Logic

1. **Authenticate**: Verify JWT, extract `user_id`
2. **Query notifications**: Select from `notifications` WHERE `user_id = auth.uid()`, with optional filters
3. **Order by** `created_at DESC`
4. **Apply pagination** via `limit` and `offset`
5. **Return** notification list with metadata

### Response

```json
{
  "notifications": [
    {
      "id": "uuid",
      "category": "shopping_list",
      "type": "item_added",
      "title": "Ahmed added Milk",
      "body": "Ahmed added Milk to Grocery List",
      "actor_id": "uuid",
      "target_route": "/shopping-lists/uuid",
      "is_read": false,
      "created_at": "2026-05-13T10:30:00Z"
    }
  ],
  "total_count": 45,
  "unread_count": 5,
  "has_more": true
}
```

---

## Function: `mark-notifications-read`

### Purpose
Mark one or more notifications as read for the authenticated user.

### Trigger
Called by Flutter client via Supabase client.

### Request

```json
{
  "notification_ids": ["uuid1", "uuid2"],
  "mark_all": false
}
```

### Processing Logic

1. **Authenticate**: Verify JWT, extract `user_id`
2. **Update notifications**: Set `is_read = TRUE` WHERE `user_id = auth.uid()` AND (id IN list OR mark_all = TRUE)
3. **Return** count of updated records

### Response

```json
{
  "success": true,
  "updated_count": 2
}
```

---

## Function: `update-notification-preferences`

### Purpose
Update notification preferences for the authenticated user.

### Trigger
Called by Flutter client via Supabase client.

### Request

```json
{
  "preferences": [
    { "category": "shopping_list", "enabled": true },
    { "category": "home_activity", "enabled": false },
    { "category": "invitation", "enabled": true }
  ]
}
```

### Processing Logic

1. **Authenticate**: Verify JWT, extract `user_id`
2. **Upsert preferences**: For each category, INSERT or UPDATE `notification_preferences`
3. **Return** updated preferences

### Response

```json
{
  "success": true,
  "preferences": [
    { "category": "shopping_list", "enabled": true },
    { "category": "home_activity", "enabled": false },
    { "category": "invitation", "enabled": true }
  ]
}
```

---

## Database Triggers

### Trigger: `notify_on_shopping_item_change`

```sql
-- Fires after INSERT or UPDATE on shopping_items
-- Calls send-notification Edge Function via pg_net
CREATE OR REPLACE FUNCTION trigger_notify_shopping_item()
RETURNS TRIGGER AS $$
DECLARE
  event_type TEXT;
  home_id UUID;
  list_name TEXT;
BEGIN
  -- Determine event type
  IF TG_OP = 'INSERT' THEN
    event_type := 'item_added';
  ELSIF OLD.is_purchased IS DISTINCT FROM NEW.is_purchased AND NEW.is_purchased THEN
    event_type := 'item_completed';
  ELSE
    event_type := 'item_updated';
  END IF;

  -- Get home_id via shopping_lists
  SELECT sl.home_id INTO home_id
  FROM shopping_lists sl
  WHERE sl.id = NEW.shopping_list_id;

  -- Call Edge Function via pg_net
  PERFORM net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'event_type', event_type,
      'home_id', home_id,
      'actor_id', NEW.created_by,
      'reference_id', NEW.shopping_list_id,
      'reference_type', 'shopping_list',
      'context', jsonb_build_object(
        'item_name', NEW.name,
        'list_name', (SELECT name FROM shopping_lists WHERE id = NEW.shopping_list_id)
      )
    )
  );

  RETURN NEW;
END;
```

### Trigger: `notify_on_invitation`

```sql
-- Fires on INSERT to invitations table
-- Sends invitation notification to invitee
```

### Trigger: `notify_on_member_joined`

```sql
-- Fires on INSERT to home_members table
-- Sends member_joined notification to existing members
```

---

## Function: `cleanup-old-notifications`

### Purpose
Delete notifications older than 30 days. Runs on a schedule.

### Trigger
Called by pg_cron daily at 03:00 UTC.

### Processing Logic

1. `DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '30 days'`
2. Log count of deleted records

### Response

```json
{
  "deleted_count": 150
}
```

---

## Notification Content Templates

### English

| Event Type | Title | Body |
|------------|-------|------|
| item_added | "{actor} added {item}" | "{actor} added {item} to {list}" |
| item_completed | "{actor} purchased {item}" | "{actor} marked {item} as purchased in {list}" |
| item_updated | "{actor} updated {item}" | "{actor} updated {item} in {list}" |
| member_joined | "New member joined" | "{actor} joined {home}" |
| invitation_received | "Invitation" | "You've been invited to {home} by {actor}" |

### Arabic

| Event Type | Title | Body |
|------------|-------|------|
| item_added | "{actor} أضاف {item}" | "{actor} أضاف {item} إلى {list}" |
| item_completed | "{actor} اشترى {item}" | "{actor} وضع علامة شراء على {item} في {list}" |
| item_updated | "{actor} حدّث {item}" | "{actor} حدّث {item} في {list}" |
| member_joined | "عضو جديد" | "{actor} انضم إلى {home}" |
| invitation_received | "دعوة" | "تمت دعوتك إلى {home} من قبل {actor}" |
