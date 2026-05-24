-- =============================================================
-- Units RLS, Secure Invitation RPC, Cross-Home Constraints, Price Columns
-- =============================================================

BEGIN;

-- =============================================================
-- 1. UNITS RLS: Allow authenticated users to manage non-default units
-- =============================================================

CREATE POLICY "Authenticated users can create custom units"
ON public.units
FOR INSERT TO authenticated
WITH CHECK (is_default = false);

CREATE POLICY "Authenticated users can update non-default units"
ON public.units
FOR UPDATE TO authenticated
USING (is_default = false)
WITH CHECK (is_default = false);

CREATE POLICY "Authenticated users can delete non-default units"
ON public.units
FOR DELETE TO authenticated
USING (is_default = false);

-- =============================================================
-- 2. SECURE INVITATION RPC: create_invitation with server-side token
-- =============================================================

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

  -- Verify caller is owner/admin of the home
  SELECT role INTO v_user_role
  FROM public.home_members
  WHERE home_id = p_home_id
    AND user_id = v_user_id
    AND status = 'active'
    AND deleted_at IS NULL;

  IF v_user_role IS NULL OR v_user_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Only owners and admins can create invitations';
  END IF;

  -- Validate role
  IF p_role NOT IN ('admin', 'member', 'viewer') THEN
    RAISE EXCEPTION 'Invalid role. Must be admin, member, or viewer';
  END IF;

  -- Check if email is already an active member
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

  -- Check for existing pending invitation
  SELECT id INTO v_existing_invitation
  FROM public.invitations
  WHERE home_id = p_home_id
    AND lower(email) = lower(p_email)
    AND status = 'pending'
    AND expires_at > now();

  IF v_existing_invitation IS NOT NULL THEN
    RAISE EXCEPTION 'A pending invitation already exists for this email';
  END IF;

  -- Create invitation with secure random token
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

  -- Log activity
  INSERT INTO public.activity_logs (home_id, user_id, action, entity_type, entity_id)
  VALUES (p_home_id, v_user_id, 'invitation_sent', 'invitation', v_invitation.id);

  RETURN row_to_json(v_invitation);
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_invitation(uuid, text, text) TO authenticated;

-- =============================================================
-- 3. ADD PRICE/CURRENCY COLUMNS TO SHOPPING_ITEMS
-- =============================================================

ALTER TABLE public.shopping_items
  ADD COLUMN IF NOT EXISTS estimated_price numeric(10,2),
  ADD COLUMN IF NOT EXISTS currency text DEFAULT 'SAR';

-- =============================================================
-- 4. CROSS-HOME CONSTRAINT TRIGGERS
-- =============================================================

-- Ensure shopping_items.category_id belongs to the same home as the list
CREATE OR REPLACE FUNCTION public.check_shopping_item_same_home()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_list_home_id uuid;
  v_category_home_id uuid;
  v_unit_home_id uuid;
BEGIN
  -- Get the home_id from the shopping list
  SELECT home_id INTO v_list_home_id
  FROM public.shopping_lists
  WHERE id = NEW.list_id;

  IF v_list_home_id IS NULL THEN
    RAISE EXCEPTION 'Shopping list not found';
  END IF;

  -- Check category belongs to same home (if provided)
  IF NEW.category_id IS NOT NULL THEN
    SELECT home_id INTO v_category_home_id
    FROM public.categories
    WHERE id = NEW.category_id;

    IF v_category_home_id IS NOT NULL AND v_category_home_id != v_list_home_id THEN
      RAISE EXCEPTION 'Category does not belong to the same home';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_shopping_item_same_home ON public.shopping_items;
CREATE TRIGGER trg_check_shopping_item_same_home
  BEFORE INSERT OR UPDATE ON public.shopping_items
  FOR EACH ROW
  EXECUTE FUNCTION public.check_shopping_item_same_home();

-- Ensure inventory_transactions.inventory_item_id belongs to the same home
CREATE OR REPLACE FUNCTION public.check_inventory_transaction_same_home()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_item_home_id uuid;
BEGIN
  SELECT home_id INTO v_item_home_id
  FROM public.inventory_items
  WHERE id = NEW.inventory_item_id;

  IF v_item_home_id IS NULL THEN
    RAISE EXCEPTION 'Inventory item not found';
  END IF;

  IF v_item_home_id != NEW.home_id THEN
    RAISE EXCEPTION 'Inventory item does not belong to the same home';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_inventory_transaction_same_home ON public.inventory_transactions;
CREATE TRIGGER trg_check_inventory_transaction_same_home
  BEFORE INSERT OR UPDATE ON public.inventory_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.check_inventory_transaction_same_home();

-- Ensure tasks.assigned_to is an active member of the same home
CREATE OR REPLACE FUNCTION public.check_task_assignee_membership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.assigned_to IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.home_members hm
      WHERE hm.home_id = NEW.home_id
        AND hm.user_id = NEW.assigned_to
        AND hm.status = 'active'
        AND hm.deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Assignee must be an active member of the home';
    END IF;
  END IF;

  IF NEW.completed_by IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.home_members hm
      WHERE hm.home_id = NEW.home_id
        AND hm.user_id = NEW.completed_by
        AND hm.status = 'active'
        AND hm.deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Completor must be an active member of the home';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_task_assignee_membership ON public.tasks;
CREATE TRIGGER trg_check_task_assignee_membership
  BEFORE INSERT OR UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.check_task_assignee_membership();

-- Ensure expenses.paid_by is an active member
CREATE OR REPLACE FUNCTION public.check_expense_member_membership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = NEW.home_id
      AND hm.user_id = NEW.paid_by
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Payer must be an active member of the home';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_expense_member_membership ON public.expenses;
CREATE TRIGGER trg_check_expense_member_membership
  BEFORE INSERT OR UPDATE ON public.expenses
  FOR EACH ROW
  EXECUTE FUNCTION public.check_expense_member_membership();

-- Ensure expense_splits.member_id is an active member
CREATE OR REPLACE FUNCTION public.check_expense_split_membership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_home_id uuid;
BEGIN
  SELECT home_id INTO v_home_id
  FROM public.expenses
  WHERE id = NEW.expense_id;

  IF v_home_id IS NULL THEN
    RAISE EXCEPTION 'Expense not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = v_home_id
      AND hm.user_id = NEW.member_id
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Split member must be an active member of the home';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_expense_split_membership ON public.expense_splits;
CREATE TRIGGER trg_check_expense_split_membership
  BEFORE INSERT OR UPDATE ON public.expense_splits
  FOR EACH ROW
  EXECUTE FUNCTION public.check_expense_split_membership();

-- Ensure settlements from_member/to_member are active members
CREATE OR REPLACE FUNCTION public.check_settlement_membership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = NEW.home_id
      AND hm.user_id = NEW.from_member
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Settlement sender must be an active member of the home';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.home_members hm
    WHERE hm.home_id = NEW.home_id
      AND hm.user_id = NEW.to_member
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Settlement receiver must be an active member of the home';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_settlement_membership ON public.settlements;
CREATE TRIGGER trg_check_settlement_membership
  BEFORE INSERT OR UPDATE ON public.settlements
  FOR EACH ROW
  EXECUTE FUNCTION public.check_settlement_membership();

-- =============================================================
-- 5. PROTECT HOME OWNERS: Prevent removing last owner or self-demotion
-- =============================================================

CREATE OR REPLACE FUNCTION public.protect_home_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_owner_count integer;
BEGIN
  -- If changing role FROM owner, ensure it's not the last owner
  IF OLD.role = 'owner' AND NEW.role != 'owner' THEN
    SELECT COUNT(*) INTO v_owner_count
    FROM public.home_members
    WHERE home_id = OLD.home_id
      AND role = 'owner'
      AND status = 'active'
      AND deleted_at IS NULL;

    IF v_owner_count <= 1 THEN
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
      AND deleted_at IS NULL;

    IF v_owner_count <= 1 THEN
      RAISE EXCEPTION 'Cannot remove the last owner. Transfer ownership first.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_home_owner ON public.home_members;
CREATE TRIGGER trg_protect_home_owner
  BEFORE UPDATE ON public.home_members
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_home_owner();

COMMIT;
