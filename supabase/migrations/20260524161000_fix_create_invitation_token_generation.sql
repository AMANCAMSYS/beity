-- =============================================================
-- Fix create_invitation token generation
-- =============================================================
-- pgcrypto is installed in the extensions schema in this project.
-- create_invitation has search_path = public, pg_temp, so unqualified
-- gen_random_bytes(...) is not visible at runtime.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.create_invitation(
  p_home_id uuid,
  p_email text,
  p_role text DEFAULT 'member'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_user_role text;
  v_existing_member uuid;
  v_existing_invitation uuid;
  v_invitation public.invitations%ROWTYPE;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT role INTO v_user_role
  FROM public.home_members
  WHERE home_id = p_home_id
    AND user_id = v_user_id
    AND status = 'active'
    AND deleted_at IS NULL;

  IF v_user_role IS NULL OR v_user_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Only owners and admins can create invitations';
  END IF;

  IF p_role NOT IN ('admin', 'member', 'viewer') THEN
    RAISE EXCEPTION 'Invalid role. Must be admin, member, or viewer';
  END IF;

  SELECT hm.user_id INTO v_existing_member
  FROM public.home_members hm
  JOIN public.users u ON u.id = hm.user_id
  WHERE hm.home_id = p_home_id
    AND lower(u.email) = lower(p_email)
    AND hm.status = 'active'
    AND hm.deleted_at IS NULL;

  IF v_existing_member IS NOT NULL THEN
    RAISE EXCEPTION 'User is already an active member of this home';
  END IF;

  SELECT id INTO v_existing_invitation
  FROM public.invitations
  WHERE home_id = p_home_id
    AND lower(email) = lower(p_email)
    AND status = 'pending'
    AND expires_at > now();

  IF v_existing_invitation IS NOT NULL THEN
    RAISE EXCEPTION 'A pending invitation already exists for this email';
  END IF;

  INSERT INTO public.invitations (
    home_id, email, role, token, status, invited_by, expires_at
  ) VALUES (
    p_home_id,
    lower(p_email),
    p_role,
    encode(extensions.gen_random_bytes(32), 'hex'),
    'pending',
    v_user_id,
    now() + INTERVAL '7 days'
  )
  RETURNING * INTO v_invitation;

  INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
  VALUES (p_home_id, v_user_id, 'invitation_sent', 'invitation', v_invitation.id);

  RETURN row_to_json(v_invitation);
END;
$$;

REVOKE ALL ON FUNCTION public.create_invitation(uuid, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_invitation(uuid, text, text) TO authenticated;

COMMIT;

