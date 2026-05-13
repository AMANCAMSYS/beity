-- Migration: Add activity log triggers and actor_name column
-- Feature: 008-activity-logs
-- Date: 2026-05-13

-- 1. Add actor_name column for denormalized display name
ALTER TABLE activity_logs ADD COLUMN IF NOT EXISTS actor_name text;

-- 2. Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs (entity_type, entity_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_home_created ON activity_logs (home_id, created_at DESC);

-- 3. Helper function to get actor name
CREATE OR REPLACE FUNCTION get_actor_name(p_user_id uuid)
RETURNS text AS $$
  SELECT full_name FROM users WHERE id = p_user_id;
$$ LANGUAGE sql STABLE;

-- 4. Trigger function: log shopping list activity
CREATE OR REPLACE FUNCTION log_shopping_list_activity()
RETURNS trigger AS $$
DECLARE
  v_action text;
  v_entity_name text;
  v_metadata jsonb;
  v_home_id uuid;
  v_user_id uuid;
  v_actor_name text;
BEGIN
  -- Get home_id and user_id
  v_home_id := NEW.home_id;
  v_user_id := COALESCE(NEW.updated_by, NEW.created_by);
  v_actor_name := get_actor_name(v_user_id);

  IF TG_OP = 'INSERT' THEN
    v_action := 'list_created';
    v_entity_name := NEW.title;
    v_metadata := NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Check for rename
    IF OLD.title IS DISTINCT FROM NEW.title THEN
      v_action := 'list_renamed';
      v_entity_name := NEW.title;
      v_metadata := jsonb_build_object('old_name', OLD.title, 'new_name', NEW.title);
    -- Check for archive
    ELSIF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'archived' THEN
      v_action := 'list_archived';
      v_entity_name := NEW.title;
      v_metadata := NULL;
    -- Check for soft delete
    ELSIF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      v_action := 'list_deleted';
      v_entity_name := NEW.title;
      v_metadata := NULL;
    ELSE
      RETURN NEW; -- No relevant change
    END IF;
  END IF;

  INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
  VALUES (v_home_id, v_user_id, v_actor_name, v_action, 'shopping_list', NEW.id, v_entity_name, v_metadata);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Trigger function: log shopping item activity
CREATE OR REPLACE FUNCTION log_shopping_item_activity()
RETURNS trigger AS $$
DECLARE
  v_action text;
  v_entity_name text;
  v_metadata jsonb;
  v_home_id uuid;
  v_user_id uuid;
  v_actor_name text;
  v_list_id uuid;
  v_list_name text;
  v_old_values jsonb;
  v_new_values jsonb;
BEGIN
  -- Get home_id from the shopping list
  IF TG_OP = 'INSERT' THEN
    v_list_id := NEW.list_id;
    SELECT sl.home_id, sl.title INTO v_home_id, v_list_name FROM shopping_lists sl WHERE sl.id = NEW.list_id;
    v_user_id := NEW.created_by;
  ELSE
    v_list_id := NEW.list_id;
    SELECT sl.home_id, sl.title INTO v_home_id, v_list_name FROM shopping_lists sl WHERE sl.id = NEW.list_id;
    v_user_id := COALESCE(NEW.updated_by, NEW.created_by);
  END IF;

  v_actor_name := get_actor_name(v_user_id);

  IF TG_OP = 'INSERT' THEN
    v_action := 'item_added';
    v_entity_name := NEW.name;
    v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
  ELSIF TG_OP = 'UPDATE' THEN
    -- Check for soft delete first
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      v_action := 'item_deleted';
      v_entity_name := NEW.name;
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
    -- Check for status change to completed (purchased)
    ELSIF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed' THEN
      v_action := 'item_purchased';
      v_entity_name := NEW.name;
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
    -- Check for status change back to pending (unpurchased)
    ELSIF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'pending' AND OLD.status = 'completed' THEN
      v_action := 'item_unpurchased';
      v_entity_name := NEW.name;
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name);
    -- Check for field updates (name, quantity, unit, category, note)
    ELSIF OLD.name IS DISTINCT FROM NEW.name
       OR OLD.quantity IS DISTINCT FROM NEW.quantity
       OR OLD.unit_id IS DISTINCT FROM NEW.unit_id
       OR OLD.category_id IS DISTINCT FROM NEW.category_id
       OR OLD.note IS DISTINCT FROM NEW.note THEN
      v_action := 'item_updated';
      v_entity_name := NEW.name;
      v_old_values := jsonb_build_object(
        'name', OLD.name,
        'quantity', OLD.quantity,
        'unit_id', OLD.unit_id,
        'category_id', OLD.category_id,
        'note', OLD.note
      );
      v_new_values := jsonb_build_object(
        'name', NEW.name,
        'quantity', NEW.quantity,
        'unit_id', NEW.unit_id,
        'category_id', NEW.category_id,
        'note', NEW.note
      );
      v_metadata := jsonb_build_object('list_id', v_list_id::text, 'list_name', v_list_name, 'old_values', v_old_values, 'new_values', v_new_values);
    ELSE
      RETURN NEW; -- No relevant change
    END IF;
  END IF;

  INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
  VALUES (v_home_id, v_user_id, v_actor_name, v_action, 'shopping_item', NEW.id, v_entity_name, v_metadata);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Trigger function: log home member activity
CREATE OR REPLACE FUNCTION log_home_member_activity()
RETURNS trigger AS $$
DECLARE
  v_action text;
  v_entity_name text;
  v_metadata jsonb;
  v_home_id uuid;
  v_user_id uuid;
  v_actor_name text;
  v_member_name text;
BEGIN
  v_home_id := NEW.home_id;
  v_user_id := auth.uid();
  v_actor_name := get_actor_name(v_user_id);
  v_member_name := get_actor_name(NEW.user_id);

  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'active' THEN
      v_action := 'member_joined';
      v_entity_name := v_member_name;
      v_metadata := NULL;
    ELSE
      RETURN NEW; -- Pending invitation, not a join yet
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Check for removal
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      v_action := 'member_removed';
      v_entity_name := v_member_name;
      v_metadata := jsonb_build_object('member_name', v_member_name);
    -- Check for role change
    ELSIF OLD.role IS DISTINCT FROM NEW.role THEN
      v_action := 'member_role_changed';
      v_entity_name := v_member_name;
      v_metadata := jsonb_build_object('old_role', OLD.role, 'new_role', NEW.role, 'member_name', v_member_name);
    ELSE
      RETURN NEW; -- No relevant change
    END IF;
  END IF;

  INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
  VALUES (v_home_id, v_user_id, v_actor_name, v_action, 'home_member', NEW.id, v_entity_name, v_metadata);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Trigger function: log invitation activity (accepted only)
CREATE OR REPLACE FUNCTION log_invitation_activity()
RETURNS trigger AS $$
DECLARE
  v_actor_name text;
  v_entity_name text;
BEGIN
  -- Only log accepted invitations
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'accepted' THEN
    v_actor_name := get_actor_name(NEW.invited_by);
    v_entity_name := COALESCE(NEW.email, NEW.phone);

    INSERT INTO activity_logs (home_id, user_id, actor_name, action, entity_type, entity_id, entity_name, metadata)
    VALUES (NEW.home_id, NEW.invited_by, v_actor_name, 'invitation_accepted', 'invitation', NEW.id, v_entity_name, NULL);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Attach triggers
DROP TRIGGER IF EXISTS trg_shopping_lists_activity ON shopping_lists;
CREATE TRIGGER trg_shopping_lists_activity
  AFTER INSERT OR UPDATE ON shopping_lists
  FOR EACH ROW EXECUTE FUNCTION log_shopping_list_activity();

DROP TRIGGER IF EXISTS trg_shopping_items_activity ON shopping_items;
CREATE TRIGGER trg_shopping_items_activity
  AFTER INSERT OR UPDATE ON shopping_items
  FOR EACH ROW EXECUTE FUNCTION log_shopping_item_activity();

DROP TRIGGER IF EXISTS trg_home_members_activity ON home_members;
CREATE TRIGGER trg_home_members_activity
  AFTER INSERT OR UPDATE ON home_members
  FOR EACH ROW EXECUTE FUNCTION log_home_member_activity();

DROP TRIGGER IF EXISTS trg_invitations_activity ON invitations;
CREATE TRIGGER trg_invitations_activity
  AFTER UPDATE ON invitations
  FOR EACH ROW EXECUTE FUNCTION log_invitation_activity();
