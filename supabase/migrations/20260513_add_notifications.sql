-- Notifications Feature Migration
-- Creates notification_preferences and notifications tables with RLS policies

-- Required extensions
CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS http SCHEMA extensions;

-- Helper function to get Supabase URL
CREATE OR REPLACE FUNCTION get_supabase_url()
RETURNS TEXT AS $$
BEGIN
  RETURN current_setting('app.settings.supabase_url', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to get service role key
CREATE OR REPLACE FUNCTION get_service_role_key()
RETURNS TEXT AS $$
BEGIN
  RETURN current_setting('app.settings.service_role_key', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 1. notification_preferences table
-- ============================================================

CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL CHECK (category IN ('shopping_list', 'home_activity', 'invitation')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_by UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, category)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user ON notification_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_preferences_lookup ON notification_preferences(user_id, category, enabled);

-- RLS
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification preferences"
ON notification_preferences FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert own notification preferences"
ON notification_preferences FOR INSERT
WITH CHECK (user_id = auth.uid() AND created_by = auth.uid());

CREATE POLICY "Users can update own notification preferences"
ON notification_preferences FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Trigger for updated_at
CREATE TRIGGER set_notification_preferences_updated_at
BEFORE UPDATE ON notification_preferences
FOR EACH ROW
EXECUTE FUNCTION moddatetime(updated_at);

-- ============================================================
-- 2. notifications table
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL CHECK (category IN ('shopping_list', 'home_activity', 'invitation')),
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  target_route VARCHAR(255),
  reference_id UUID,
  reference_type VARCHAR(50),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  batch_key VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_batch ON notifications(batch_key, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_home ON notifications(user_id, home_id, created_at DESC);

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
ON notifications FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Service can insert notifications"
ON notifications FOR INSERT
WITH CHECK (TRUE);

CREATE POLICY "Users can update own notifications"
ON notifications FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own notifications"
ON notifications FOR DELETE
USING (user_id = auth.uid());

-- ============================================================
-- 3. Default notification preferences for new users
-- ============================================================

CREATE OR REPLACE FUNCTION create_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notification_preferences (user_id, category, enabled, created_by)
  VALUES
    (NEW.id, 'shopping_list', TRUE, NEW.id),
    (NEW.id, 'home_activity', TRUE, NEW.id),
    (NEW.id, 'invitation', TRUE, NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created_notification_preferences
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_default_notification_preferences();

-- ============================================================
-- 4. Seed default preferences for existing users
-- ============================================================

INSERT INTO notification_preferences (user_id, category, enabled, created_by)
SELECT u.id, cat.category, TRUE, u.id
FROM auth.users u
CROSS JOIN (VALUES ('shopping_list'), ('home_activity'), ('invitation')) AS cat(category)
LEFT JOIN notification_preferences np ON np.user_id = u.id AND np.category = cat.category
WHERE np.id IS NULL;

-- ============================================================
-- 5. pg_cron job for 30-day cleanup
-- ============================================================

-- Enable pg_cron extension if not already enabled
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily cleanup at 03:00 UTC
-- SELECT cron.schedule(
--   'delete-old-notifications',
--   '0 3 * * *',
--   $$DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '30 days'$$
-- );

-- Note: pg_cron must be enabled via Supabase dashboard or CLI
-- For now, the cleanup-old-notifications Edge Function handles this

-- ============================================================
-- 6. Database trigger: notify on shopping item changes
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_notify_shopping_item()
RETURNS TRIGGER AS $$
DECLARE
  v_event_type TEXT;
  v_home_id UUID;
  v_list_name TEXT;
  v_home_name TEXT;
BEGIN
  -- Determine event type
  IF TG_OP = 'INSERT' THEN
    v_event_type := 'item_added';
  ELSIF OLD.is_purchased IS DISTINCT FROM NEW.is_purchased AND NEW.is_purchased THEN
    v_event_type := 'item_completed';
  ELSE
    v_event_type := 'item_updated';
  END IF;

  -- Get home_id and list name via shopping_lists
  SELECT sl.home_id, sl.name INTO v_home_id, v_list_name
  FROM shopping_lists sl
  WHERE sl.id = NEW.shopping_list_id;

  -- Get home name
  SELECT name INTO v_home_name
  FROM homes
  WHERE id = v_home_id;

  -- Call send-notification Edge Function via pg_net
  PERFORM net.http_post(
    url := get_supabase_url() || '/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || get_service_role_key(),
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'event_type', v_event_type,
      'home_id', v_home_id,
      'actor_id', NEW.created_by,
      'reference_id', NEW.shopping_list_id,
      'reference_type', 'shopping_list',
      'context', jsonb_build_object(
        'item_name', NEW.name,
        'list_name', v_list_name,
        'home_name', v_home_name
      )
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER notify_on_shopping_item_change
AFTER INSERT OR UPDATE ON shopping_items
FOR EACH ROW
EXECUTE FUNCTION trigger_notify_shopping_item();

-- ============================================================
-- 7. Database trigger: notify on invitation
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_notify_invitation()
RETURNS TRIGGER AS $$
DECLARE
  v_home_name TEXT;
  v_inviter_name TEXT;
BEGIN
  -- Get home name
  SELECT name INTO v_home_name
  FROM homes
  WHERE id = NEW.home_id;

  -- Get inviter name
  SELECT full_name INTO v_inviter_name
  FROM profiles
  WHERE id = NEW.invited_by;

  -- Call send-notification Edge Function via pg_net
  PERFORM net.http_post(
    url := get_supabase_url() || '/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || get_service_role_key(),
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'event_type', 'invitation_received',
      'home_id', NEW.home_id,
      'actor_id', NEW.invited_by,
      'reference_id', NEW.id,
      'reference_type', 'invitation',
      'context', jsonb_build_object(
        'home_name', v_home_name,
        'actor', COALESCE(v_inviter_name, 'Someone')
      )
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER notify_on_invitation
AFTER INSERT ON invitations
FOR EACH ROW
EXECUTE FUNCTION trigger_notify_invitation();

-- ============================================================
-- 8. Database trigger: notify on member joined
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_notify_member_joined()
RETURNS TRIGGER AS $$
DECLARE
  v_home_name TEXT;
  v_member_name TEXT;
BEGIN
  -- Get home name
  SELECT name INTO v_home_name
  FROM homes
  WHERE id = NEW.home_id;

  -- Get member name
  SELECT full_name INTO v_member_name
  FROM profiles
  WHERE id = NEW.user_id;

  -- Call send-notification Edge Function via pg_net
  -- Notifies all existing members except the one who just joined
  PERFORM net.http_post(
    url := get_supabase_url() || '/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || get_service_role_key(),
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'event_type', 'member_joined',
      'home_id', NEW.home_id,
      'actor_id', NEW.user_id,
      'reference_id', NEW.home_id,
      'reference_type', 'home',
      'context', jsonb_build_object(
        'home_name', v_home_name,
        'actor', COALESCE(v_member_name, 'Someone'),
        'member_name', COALESCE(v_member_name, 'Someone')
      )
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER notify_on_member_joined
AFTER INSERT ON home_members
FOR EACH ROW
EXECUTE FUNCTION trigger_notify_member_joined();
