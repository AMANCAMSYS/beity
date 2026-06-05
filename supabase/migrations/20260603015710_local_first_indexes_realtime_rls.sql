-- Local-first MVP hardening for efficient delta sync and Realtime.
--
-- Notes:
-- - Plain CREATE INDEX is used instead of CONCURRENTLY because Supabase
--   migration files run inside a transaction.
-- - All statements are idempotent so this migration can be safely replayed.
-- - Existing RLS policies already protect these public tables; this migration
--   keeps RLS enabled and only ensures Realtime publication coverage.

-- Delta sync indexes for Phase 1 tables.
CREATE INDEX IF NOT EXISTS idx_shopping_items_home_updated
ON public.shopping_items (home_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_item_templates_home_updated
ON public.item_templates (home_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_home_members_home_updated
ON public.home_members (home_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_shopping_mode_sessions_home_updated
ON public.shopping_mode_sessions (home_id, updated_at DESC);

-- Keep RLS enabled for every public Phase 1 table used by local-first sync.
ALTER TABLE public.homes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_mode_sessions ENABLE ROW LEVEL SECURITY;

-- Delta sync must be able to read tombstone rows. Existing UI policies keep
-- normal app queries filtered by deleted_at; these additive policies only widen
-- SELECT for authenticated members of the same home.
DROP POLICY IF EXISTS "Users can sync homes including deleted" ON public.homes;
CREATE POLICY "Users can sync homes including deleted"
ON public.homes
FOR SELECT
TO authenticated
USING (owner_id = auth.uid() OR public.is_home_member(id));

DROP POLICY IF EXISTS "Users can sync members including deleted" ON public.home_members;
CREATE POLICY "Users can sync members including deleted"
ON public.home_members
FOR SELECT
TO authenticated
USING (public.is_home_member(home_id));

DROP POLICY IF EXISTS "Users can sync lists including deleted" ON public.shopping_lists;
CREATE POLICY "Users can sync lists including deleted"
ON public.shopping_lists
FOR SELECT
TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id
    FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can sync items including deleted" ON public.shopping_items;
CREATE POLICY "Users can sync items including deleted"
ON public.shopping_items
FOR SELECT
TO authenticated
USING (
  home_id IN (
    SELECT hm.home_id
    FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Users can sync categories including deleted" ON public.categories;
CREATE POLICY "Users can sync categories including deleted"
ON public.categories
FOR SELECT
TO authenticated
USING (
  is_default = true
  OR home_id IN (
    SELECT hm.home_id
    FROM public.home_members hm
    WHERE hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  )
);

-- Ensure Realtime publication includes the local-first Phase 1 tables.
DO $$
DECLARE
  v_table regclass;
  v_schema text;
  v_name text;
  v_tables regclass[] := ARRAY[
    'public.homes'::regclass,
    'public.home_members'::regclass,
    'public.shopping_lists'::regclass,
    'public.shopping_items'::regclass,
    'public.item_templates'::regclass,
    'public.categories'::regclass,
    'public.units'::regclass,
    'public.activity_logs'::regclass,
    'public.shopping_mode_sessions'::regclass
  ];
BEGIN
  FOREACH v_table IN ARRAY v_tables LOOP
    SELECT n.nspname, c.relname
    INTO v_schema, v_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.oid = v_table;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = v_schema
        AND tablename = v_name
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %s', v_table);
    END IF;
  END LOOP;
END;
$$;

-- Expand the sync cursor RPC to cover all Phase 1 local-first tables.
CREATE OR REPLACE FUNCTION public.get_tables_last_update(p_home_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members
    WHERE home_id = p_home_id
      AND user_id = auth.uid()
      AND status = 'active'
      AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  v_result := jsonb_build_object(
    'homes', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.homes
      WHERE id = p_home_id
    ),
    'home_members', (
      SELECT COALESCE(MAX(COALESCE(updated_at, joined_at)), '1970-01-01'::timestamptz)
      FROM public.home_members
      WHERE home_id = p_home_id
    ),
    'shopping_lists', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.shopping_lists
      WHERE home_id = p_home_id
    ),
    'shopping_items', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.shopping_items
      WHERE home_id = p_home_id
    ),
    'item_templates', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.item_templates
      WHERE home_id = p_home_id
    ),
    'categories', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.categories
      WHERE is_default = true OR home_id = p_home_id
    ),
    'units', (
      SELECT COALESCE(MAX(created_at), '1970-01-01'::timestamptz)
      FROM public.units
    ),
    'activity_logs', (
      SELECT COALESCE(MAX(created_at), '1970-01-01'::timestamptz)
      FROM public.activity_logs
      WHERE home_id = p_home_id
    ),
    'shopping_mode_sessions', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.shopping_mode_sessions
      WHERE home_id = p_home_id
    ),
    'tasks', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.tasks
      WHERE home_id = p_home_id
    ),
    'inventory_items', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.inventory_items
      WHERE home_id = p_home_id
    ),
    'expenses', (
      SELECT COALESCE(MAX(COALESCE(updated_at, created_at)), '1970-01-01'::timestamptz)
      FROM public.expenses
      WHERE home_id = p_home_id
    )
  );

  RETURN v_result;
END;
$$;
