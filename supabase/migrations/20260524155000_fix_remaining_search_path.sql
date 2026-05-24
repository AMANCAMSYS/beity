-- =============================================================
-- Add search_path to remaining SECURITY DEFINER functions
-- =============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.log_shopping_list_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_action text;
  v_home_id uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_action := 'list_created';
    v_home_id := NEW.home_id;
    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
    VALUES (v_home_id, NEW.created_by, v_action, 'shopping_list', NEW.id,
      jsonb_build_object('title', NEW.title));
  ELSIF TG_OP = 'UPDATE' THEN
    v_home_id := NEW.home_id;
    IF OLD.title IS DISTINCT FROM NEW.title THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'list_renamed', 'shopping_list', NEW.id,
        jsonb_build_object('old_title', OLD.title, 'new_title', NEW.title));
    END IF;
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'list_' || NEW.status, 'shopping_list', NEW.id,
        jsonb_build_object('old_status', OLD.status, 'new_status', NEW.status));
    END IF;
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'list_deleted', 'shopping_list', NEW.id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.log_shopping_item_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_home_id uuid;
  v_list_title text;
BEGIN
  SELECT sl.home_id, sl.title INTO v_home_id, v_list_title
  FROM public.shopping_lists sl
  WHERE sl.id = COALESCE(NEW.list_id, OLD.list_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
    VALUES (v_home_id, NEW.created_by, 'item_added', 'shopping_item', NEW.id,
      jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'item_deleted', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
    IF NEW.status = 'completed' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.completed_by, NEW.updated_by, NEW.created_by), 'item_purchased', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
    IF NEW.status = 'pending' AND OLD.status = 'completed' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'item_unpurchased', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
    IF OLD.name IS DISTINCT FROM NEW.name OR OLD.quantity IS DISTINCT FROM NEW.quantity THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (v_home_id, COALESCE(NEW.updated_by, NEW.created_by), 'item_updated', 'shopping_item', NEW.id,
        jsonb_build_object('name', NEW.name, 'list_title', v_list_title));
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

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
    VALUES (NEW.home_id, v_actor, v_action, 'home_member', NEW.user_id::text::uuid,
      jsonb_build_object('user_id', NEW.user_id, 'role', NEW.role));
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.role IS DISTINCT FROM NEW.role THEN
      v_actor := COALESCE(NEW.updated_by, NEW.user_id);
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (NEW.home_id, v_actor, 'role_changed', 'home_member', NEW.user_id::text::uuid,
        jsonb_build_object('user_id', NEW.user_id, 'old_role', OLD.role, 'new_role', NEW.role));
    END IF;
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
      v_actor := COALESCE(NEW.updated_by, NEW.user_id);
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id, metadata)
      VALUES (NEW.home_id, v_actor, 'member_removed', 'home_member', NEW.user_id::text::uuid,
        jsonb_build_object('user_id', NEW.user_id));
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.log_invitation_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (NEW.home_id, NEW.invited_by, 'invitation_accepted', 'invitation', NEW.id);
    ELSIF NEW.status = 'cancelled' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (NEW.home_id, NEW.invited_by, 'invitation_cancelled', 'invitation', NEW.id);
    ELSIF NEW.status = 'expired' AND OLD.status = 'pending' THEN
      INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
      VALUES (NEW.home_id, NEW.invited_by, 'invitation_expired', 'invitation', NEW.id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_invitee_on_invitation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_home_name text;
  v_actor_name text;
BEGIN
  SELECT id INTO v_user_id FROM public.users WHERE lower(email) = lower(NEW.email);
  IF v_user_id IS NULL THEN RETURN NEW; END IF;

  SELECT name INTO v_home_name FROM public.homes WHERE id = NEW.home_id;
  SELECT full_name INTO v_actor_name FROM public.users WHERE id = NEW.invited_by;

  INSERT INTO public.notifications (user_id, home_id, category, type, title, body, actor_id, reference_id, reference_type, target_route)
  VALUES (v_user_id, NEW.home_id, 'invitation', 'invitation_received',
    'دعوة', 'تمت دعوتك إلى ' || COALESCE(v_home_name, 'المنزل') || ' من قبل ' || COALESCE(v_actor_name, 'شخص'),
    NEW.invited_by, NEW.id, 'invitation', '/invitations');

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_inviter_on_invitation_response()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_home_name text;
  v_invitee_name text;
  v_title text;
  v_body text;
BEGIN
  IF NEW.status NOT IN ('accepted', 'cancelled', 'declined') THEN RETURN NEW; END IF;
  IF OLD.status != 'pending' THEN RETURN NEW; END IF;

  SELECT name INTO v_home_name FROM public.homes WHERE id = NEW.home_id;
  SELECT full_name INTO v_invitee_name FROM public.users WHERE lower(email) = lower(NEW.email);

  IF NEW.status = 'accepted' THEN
    v_title := 'دعوة مقبولة';
    v_body := COALESCE(v_invitee_name, 'شخص') || ' قبل دعوتك للانضمام إلى ' || COALESCE(v_home_name, 'المنزل');
  ELSIF NEW.status = 'cancelled' THEN
    v_title := 'دعوة ملغاة';
    v_body := 'تم إلغاء الدعوة المرسلة إلى ' || COALESCE(v_invitee_name, 'شخص');
  ELSE
    v_title := 'دعوة مرفوضة';
    v_body := COALESCE(v_invitee_name, 'شخص') || ' رفض دعوتك للانضمام إلى ' || COALESCE(v_home_name, 'المنزل');
  END IF;

  -- Delete stale pending notification for this invitation
  DELETE FROM public.notifications
  WHERE reference_id = NEW.id AND reference_type = 'invitation' AND type = 'invitation_received';

  INSERT INTO public.notifications (user_id, home_id, category, type, title, body, actor_id, reference_id, reference_type, target_route)
  VALUES (NEW.invited_by, NEW.home_id, 'invitation', 'invitation_' || NEW.status,
    v_title, v_body,
    (SELECT id FROM public.users WHERE lower(email) = lower(NEW.email)),
    NEW.id, 'invitation', '/invitations');

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_task_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_expenses_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

COMMIT;
