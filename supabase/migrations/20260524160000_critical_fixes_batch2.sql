-- =============================================================
-- Comprehensive fix for all critical DB issues
-- =============================================================

BEGIN;

-- =============================================================
-- 1. Add created_by to home_members (missing column)
-- =============================================================
ALTER TABLE public.home_members
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id);

-- =============================================================
-- 2. Fix accept_invitation: use correct column names
-- =============================================================
CREATE OR REPLACE FUNCTION public.accept_invitation(invitation_token text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_invitation record;
    v_user_id uuid;
    v_user_email text;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt()->>'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_invitation
    FROM public.invitations
    WHERE token = invitation_token AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found or not pending';
    END IF;

    IF v_invitation.expires_at < now() THEN
        UPDATE public.invitations SET status = 'expired' WHERE id = v_invitation.id;
        RAISE EXCEPTION 'Invitation expired';
    END IF;

    IF lower(v_invitation.email) != lower(v_user_email) THEN
        RAISE EXCEPTION 'Unauthorized to accept this invitation';
    END IF;

    UPDATE public.invitations
    SET status = 'accepted', accepted_at = now()
    WHERE id = v_invitation.id
    RETURNING * INTO v_invitation;

    INSERT INTO public.home_members (home_id, user_id, role, status, joined_at, created_by)
    VALUES (v_invitation.home_id, v_user_id, v_invitation.role, 'active', now(), v_invitation.invited_by)
    ON CONFLICT (home_id, user_id)
    DO UPDATE SET
      role = EXCLUDED.role,
      status = 'active',
      deleted_at = NULL,
      joined_at = now(),
      updated_at = now(),
      updated_by = v_user_id;

    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
    VALUES (v_invitation.home_id, v_user_id, 'invitation_accepted', 'invitation', v_invitation.id);

    RETURN row_to_json(v_invitation);
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_invitation(text) TO authenticated;

-- =============================================================
-- 3. Fix log_home_member_activity: use created_by/updated_by
-- =============================================================
CREATE OR REPLACE FUNCTION public.log_home_member_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_action text;
  v_actor uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_action := 'member_joined';
    v_actor := COALESCE(NEW.created_by, NEW.user_id);
    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
    VALUES (NEW.home_id, v_actor, v_action, 'home_member', NEW.user_id,
      jsonb_build_object('user_id', NEW.user_id, 'role', NEW.role));
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.role IS DISTINCT FROM NEW.role THEN
      v_actor := COALESCE(NEW.updated_by, NEW.user_id);
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (NEW.home_id, v_actor, 'role_changed', 'home_member', NEW.user_id,
        jsonb_build_object('user_id', NEW.user_id, 'old_role', OLD.role, 'new_role', NEW.role));
    END IF;
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      v_actor := COALESCE(NEW.updated_by, NEW.user_id);
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (NEW.home_id, v_actor, 'member_removed', 'home_member', NEW.user_id,
        jsonb_build_object('user_id', NEW.user_id));
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- =============================================================
-- 4. Fix invitation policy: drop correct name
-- =============================================================
DROP POLICY IF EXISTS "Invited users can update their invitations" ON public.invitations;
DROP POLICY IF EXISTS "Invited users can accept or cancel their invitations" ON public.invitations;
DROP POLICY IF EXISTS "Invited users can cancel only their pending invitations" ON public.invitations;

CREATE POLICY "Invited users can cancel only their pending invitations"
ON public.invitations
FOR UPDATE
TO authenticated
USING (
  lower(email) = lower((auth.jwt() ->> 'email'))
  AND status = 'pending'
  AND expires_at > now()
)
WITH CHECK (
  lower(email) = lower((auth.jwt() ->> 'email'))
  AND status = 'cancelled'
);

-- =============================================================
-- 5. Fix protect_home_owner: allow transfer (two-step update)
-- =============================================================
CREATE OR REPLACE FUNCTION public.protect_home_owner()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_owner_count integer;
BEGIN
  -- If changing role FROM owner, ensure it's not the last owner
  -- BUT allow if the new role is also being set in the same transaction
  IF OLD.role = 'owner' AND NEW.role != 'owner' THEN
    -- Check if there's another active owner (excluding self)
    SELECT COUNT(*) INTO v_owner_count
    FROM public.home_members
    WHERE home_id = OLD.home_id
      AND role = 'owner'
      AND status = 'active'
      AND deleted_at IS NULL
      AND user_id != OLD.user_id;

    -- If no other owner exists, block the demotion
    IF v_owner_count = 0 THEN
      RAISE EXCEPTION 'Cannot demote the last owner. Transfer ownership first.';
    END IF;
  END IF;

  -- If soft-deleting an owner, ensure it's not the last owner
  IF OLD.role = 'owner' AND NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    SELECT COUNT(*) INTO v_owner_count
    FROM public.home_members
    WHERE home_id = OLD.home_id
      AND role = 'owner'
      AND status = 'active'
      AND deleted_at IS NULL
      AND user_id != OLD.user_id;

    IF v_owner_count = 0 THEN
      RAISE EXCEPTION 'Cannot remove the last owner. Transfer ownership first.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- =============================================================
-- 6. Fix inventory unique index for NULL unit_id
-- =============================================================
DROP INDEX IF EXISTS public.uq_inventory_items_active_home_name_unit;

CREATE UNIQUE INDEX uq_inventory_items_active_home_name_unit
ON public.inventory_items (home_id, lower(name), COALESCE(unit_id, '00000000-0000-0000-0000-000000000000'::uuid))
WHERE deleted_at IS NULL;

-- =============================================================
-- 7. Add beta_feedback table
-- =============================================================
CREATE TABLE IF NOT EXISTS public.beta_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  feedback_type text NOT NULL CHECK (feedback_type IN ('bug', 'survey')),
  description text NOT NULL,
  star_rating integer CHECK (star_rating >= 1 AND star_rating <= 5),
  device_info jsonb,
  screen_route text,
  app_logs jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.beta_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own feedback"
ON public.beta_feedback
FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view own feedback"
ON public.beta_feedback
FOR SELECT TO authenticated
USING (user_id = auth.uid());

-- =============================================================
-- 8. Fix getNotificationHistory: pass homeId filter
-- =============================================================
CREATE OR REPLACE FUNCTION public.get_notification_history(
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0,
  p_home_id uuid DEFAULT NULL,
  p_category text DEFAULT NULL,
  p_unread_only boolean DEFAULT false
) RETURNS SETOF jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT jsonb_build_object(
    'id', n.id,
    'user_id', n.user_id,
    'home_id', n.home_id,
    'category', COALESCE(n.category, n.type),
    'type', n.type,
    'title', n.title,
    'body', n.body,
    'actor_id', n.actor_id,
    'target_route', n.target_route,
    'reference_id', n.reference_id,
    'reference_type', n.reference_type,
    'is_read', n.is_read,
    'batch_key', n.batch_key,
    'created_at', n.created_at
  )
  FROM public.notifications n
  WHERE n.user_id = auth.uid()
    AND (p_home_id IS NULL OR n.home_id = p_home_id)
    AND (p_category IS NULL OR COALESCE(n.category, n.type) = p_category)
    AND (NOT p_unread_only OR n.is_read = false)
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_notification_history(integer, integer, uuid, text, boolean) TO authenticated;

COMMIT;
