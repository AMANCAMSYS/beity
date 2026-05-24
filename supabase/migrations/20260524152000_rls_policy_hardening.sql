-- =============================================================
-- RLS Policy Hardening: Active Membership Checks
-- =============================================================
-- Fixes HIGH-DB-01: Policies that check membership without
-- verifying status='active' AND deleted_at IS NULL
-- =============================================================

BEGIN;

-- =============================================================
-- EXPENSES
-- =============================================================

DROP POLICY IF EXISTS "Members can insert expenses" ON public.expenses;
CREATE POLICY "Members can insert expenses" ON public.expenses
FOR INSERT TO authenticated
WITH CHECK (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
  AND created_by = auth.uid()
);

DROP POLICY IF EXISTS "Members can update home expenses" ON public.expenses;
CREATE POLICY "Members can update home expenses" ON public.expenses
FOR UPDATE TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Members can view home expenses" ON public.expenses;
CREATE POLICY "Members can view home expenses" ON public.expenses
FOR SELECT TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- EXPENSE SPLITS
-- =============================================================

DROP POLICY IF EXISTS "Members can insert expense splits" ON public.expense_splits;
CREATE POLICY "Members can insert expense splits" ON public.expense_splits
FOR INSERT TO authenticated
WITH CHECK (
  expense_id IN (
    SELECT e.id FROM public.expenses e
    JOIN public.home_members hm ON hm.home_id = e.home_id
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Members can update expense splits" ON public.expense_splits;
CREATE POLICY "Members can update expense splits" ON public.expense_splits
FOR UPDATE TO authenticated
USING (
  expense_id IN (
    SELECT e.id FROM public.expenses e
    JOIN public.home_members hm ON hm.home_id = e.home_id
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Members can view expense splits" ON public.expense_splits;
CREATE POLICY "Members can view expense splits" ON public.expense_splits
FOR SELECT TO authenticated
USING (
  expense_id IN (
    SELECT e.id FROM public.expenses e
    JOIN public.home_members hm ON hm.home_id = e.home_id
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Members can delete expense splits" ON public.expense_splits;
CREATE POLICY "Members can delete expense splits" ON public.expense_splits
FOR DELETE TO authenticated
USING (
  expense_id IN (
    SELECT e.id FROM public.expenses e
    JOIN public.home_members hm ON hm.home_id = e.home_id
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- SETTLEMENTS
-- =============================================================

DROP POLICY IF EXISTS "Members can insert settlements" ON public.settlements;
CREATE POLICY "Members can insert settlements" ON public.settlements
FOR INSERT TO authenticated
WITH CHECK (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
  AND created_by = auth.uid()
);

DROP POLICY IF EXISTS "Members can view home settlements" ON public.settlements;
CREATE POLICY "Members can view home settlements" ON public.settlements
FOR SELECT TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- INVENTORY ITEMS
-- =============================================================

DROP POLICY IF EXISTS "Users can add inventory items" ON public.inventory_items;
CREATE POLICY "Users can add inventory items" ON public.inventory_items
FOR INSERT TO authenticated
WITH CHECK (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
  AND created_by = auth.uid()
);

DROP POLICY IF EXISTS "Users can view inventory items for their homes" ON public.inventory_items;
CREATE POLICY "Users can view inventory items for their homes" ON public.inventory_items
FOR SELECT TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can update inventory items" ON public.inventory_items;
CREATE POLICY "Users can update inventory items" ON public.inventory_items
FOR UPDATE TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can delete inventory items" ON public.inventory_items;
CREATE POLICY "Users can delete inventory items" ON public.inventory_items
FOR DELETE TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- INVENTORY TRANSACTIONS
-- =============================================================

DROP POLICY IF EXISTS "Users can create inventory transactions" ON public.inventory_transactions;
CREATE POLICY "Users can create inventory transactions" ON public.inventory_transactions
FOR INSERT TO authenticated
WITH CHECK (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can view inventory transactions" ON public.inventory_transactions;
CREATE POLICY "Users can view inventory transactions" ON public.inventory_transactions
FOR SELECT TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- ITEM TEMPLATES
-- =============================================================

DROP POLICY IF EXISTS "Users can create item templates" ON public.item_templates;
CREATE POLICY "Users can create item templates" ON public.item_templates
FOR INSERT TO authenticated
WITH CHECK (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
  AND created_by = auth.uid()
);

DROP POLICY IF EXISTS "Users can view item templates" ON public.item_templates;
CREATE POLICY "Users can view item templates" ON public.item_templates
FOR SELECT TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can update item templates" ON public.item_templates;
CREATE POLICY "Users can update item templates" ON public.item_templates
FOR UPDATE TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can delete item templates" ON public.item_templates;
CREATE POLICY "Users can delete item templates" ON public.item_templates
FOR DELETE TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- SHOPPING MODE SESSIONS
-- =============================================================

DROP POLICY IF EXISTS "Users can create sessions in their home" ON public.shopping_mode_sessions;
CREATE POLICY "Users can create sessions in their home" ON public.shopping_mode_sessions
FOR INSERT TO authenticated
WITH CHECK (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
  AND user_id = auth.uid()
);

DROP POLICY IF EXISTS "Users can view sessions in their home" ON public.shopping_mode_sessions;
CREATE POLICY "Users can view sessions in their home" ON public.shopping_mode_sessions
FOR SELECT TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- ACTIVITY LOGS
-- =============================================================

DROP POLICY IF EXISTS "Authenticated users can insert activity logs" ON public.activity_logs;
CREATE POLICY "Authenticated users can insert activity logs" ON public.activity_logs
FOR INSERT TO authenticated
WITH CHECK (
  user_id = auth.uid()
  AND home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can view activity from their homes" ON public.activity_logs;
CREATE POLICY "Users can view activity from their homes" ON public.activity_logs
FOR SELECT TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- =============================================================
-- FIX SECURITY DEFINER FUNCTIONS: Add search_path
-- =============================================================

-- These functions are SECURITY DEFINER but lack SET search_path
-- which is a security risk (search_path hijacking)

-- get_notification_history
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

-- get_actor_name
CREATE OR REPLACE FUNCTION public.get_actor_name(p_user_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT full_name FROM public.users WHERE id = p_user_id;
$$;

-- auto_archive_completed_tasks
CREATE OR REPLACE FUNCTION public.auto_archive_completed_tasks()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.tasks
  SET archived_at = now()
  WHERE status = 'completed'
    AND completed_at < now() - INTERVAL '7 days'
    AND archived_at IS NULL
    AND deleted_at IS NULL;
END;
$$;

-- =============================================================
-- REVOKE OVERLY BROAD ANON GRANTS
-- =============================================================

-- Revoke default privileges that grant to anon
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
REVOKE ALL ON FUNCTIONS FROM anon;

-- Revoke execute on all existing functions from anon
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT routine_name, routine_schema
    FROM information_schema.routines
    WHERE routine_schema = 'public'
      AND routine_type = 'FUNCTION'
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION public.%I FROM anon', r.routine_name);
  END LOOP;
END $$;

-- Re-grant specific functions that need to be publicly accessible
-- (none needed for anon - all require authentication)

COMMIT;
