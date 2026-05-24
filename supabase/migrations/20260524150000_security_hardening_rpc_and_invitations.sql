-- =============================================================
-- Security Hardening: RPCs and Invitations
-- =============================================================
-- Fixes:
-- 1. calculate_home_balances: add search_path, auth+membership check, revoke from anon
-- 2. has_unsettled_balances: add search_path, auth+membership check, revoke from anon
-- 3. accept_invitation: add search_path, revoke from anon
-- 4. Tighten invitation UPDATE policies
-- 5. Add updated_at/updated_by to home_members
-- =============================================================

BEGIN;

-- =============================================================
-- 1. Secure calculate_home_balances
-- =============================================================

REVOKE ALL ON FUNCTION public.calculate_home_balances(uuid) FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.calculate_home_balances(p_home_id uuid)
RETURNS TABLE(member_a uuid, member_b uuid, net_amount integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Require authentication
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Require active home membership
  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  WITH expense_debts AS (
    SELECT
      es.member_id as debtor,
      e.paid_by as creditor,
      SUM(es.amount)::integer as total_owed
    FROM public.expense_splits es
    JOIN public.expenses e ON e.id = es.expense_id
    WHERE e.home_id = p_home_id
      AND e.status = 'active'
      AND e.deleted_at IS NULL
    GROUP BY es.member_id, e.paid_by
  ),
  settlement_credits AS (
    SELECT
      s.from_member as debtor,
      s.to_member as creditor,
      SUM(s.amount)::integer as total_settled
    FROM public.settlements s
    WHERE s.home_id = p_home_id
    GROUP BY s.from_member, s.to_member
  ),
  all_pairs AS (
    SELECT debtor, creditor FROM expense_debts
    UNION
    SELECT debtor, creditor FROM settlement_credits
  ),
  net_balances AS (
    SELECT
      ap.debtor,
      ap.creditor,
      (COALESCE(ed.total_owed, 0) - COALESCE(sc.total_settled, 0))::integer as net_amount
    FROM all_pairs ap
    LEFT JOIN expense_debts ed ON ed.debtor = ap.debtor AND ed.creditor = ap.creditor
    LEFT JOIN settlement_credits sc ON sc.debtor = ap.debtor AND sc.creditor = ap.creditor
  )
  SELECT
    nb.debtor as member_a,
    nb.creditor as member_b,
    nb.net_amount
  FROM net_balances nb
  WHERE nb.net_amount != 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.calculate_home_balances(uuid) TO authenticated;

-- =============================================================
-- 2. Secure has_unsettled_balances
-- =============================================================

REVOKE ALL ON FUNCTION public.has_unsettled_balances(uuid, uuid) FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.has_unsettled_balances(
  p_home_id uuid,
  p_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE has_balance boolean;
BEGIN
  -- Require authentication
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Require active home membership for caller
  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Only allow checking own balances unless caller is owner/admin
  IF auth.uid() <> p_user_id AND NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = auth.uid()
      AND hm.role IN ('owner', 'admin')
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.calculate_home_balances(p_home_id)
    WHERE member_a = p_user_id OR member_b = p_user_id
  ) INTO has_balance;
  RETURN has_balance;
END;
$$;

GRANT EXECUTE ON FUNCTION public.has_unsettled_balances(uuid, uuid) TO authenticated;

-- =============================================================
-- 3. Secure accept_invitation
-- =============================================================

REVOKE ALL ON FUNCTION public.accept_invitation(text) FROM anon, authenticated;

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

    -- Get invitation (lock the row)
    SELECT * INTO v_invitation
    FROM public.invitations
    WHERE token = invitation_token AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found or not pending';
    END IF;

    -- Check if expired
    IF v_invitation.expires_at < now() THEN
        UPDATE public.invitations SET status = 'expired' WHERE id = v_invitation.id;
        RAISE EXCEPTION 'Invitation expired';
    END IF;

    -- Ensure the user's email matches the invitation email
    IF lower(v_invitation.email) != lower(v_user_email) THEN
        RAISE EXCEPTION 'Unauthorized to accept this invitation';
    END IF;

    -- Update invitation status
    UPDATE public.invitations
    SET status = 'accepted', accepted_at = now()
    WHERE id = v_invitation.id
    RETURNING * INTO v_invitation;

    -- Add user to home_members if not already a member
    INSERT INTO public.home_members (home_id, user_id, role, status, joined_at, created_by)
    VALUES (v_invitation.home_id, v_user_id, v_invitation.role, 'active', now(), v_invitation.invited_by)
    ON CONFLICT (home_id, user_id)
    DO UPDATE SET
      role = EXCLUDED.role,
      status = 'active',
      deleted_at = NULL,
      joined_at = now();

    -- Log activity
    INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
    VALUES (v_invitation.home_id, v_user_id, 'invitation_accepted', 'invitation', v_invitation.id);

    -- Return the updated invitation as JSON
    RETURN row_to_json(v_invitation);
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_invitation(text) TO authenticated;

-- =============================================================
-- 4. Tighten invitation UPDATE policies
-- =============================================================

-- Drop overly permissive policies
DROP POLICY IF EXISTS "Invited users can accept or cancel their invitations" ON public.invitations;
DROP POLICY IF EXISTS "Users can update their own pending invitations" ON public.invitations;

-- Ensure only one safe policy for invitee updates: can only cancel their own pending invitations
-- (Acceptance must go through the RPC)
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
-- 5. Add updated_at/updated_by to home_members
-- =============================================================

ALTER TABLE public.home_members
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id);

-- Create trigger for auto-updating updated_at
CREATE OR REPLACE FUNCTION public.set_home_members_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_home_members_updated_at ON public.home_members;
CREATE TRIGGER trg_home_members_updated_at
  BEFORE UPDATE ON public.home_members
  FOR EACH ROW
  EXECUTE FUNCTION public.set_home_members_updated_at();

COMMIT;
