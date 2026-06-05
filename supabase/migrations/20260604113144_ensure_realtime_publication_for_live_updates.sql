-- Ensure every table subscribed by RealtimeSyncService is present in the
-- Supabase Realtime publication. This is idempotent and safe to replay.
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
    'public.shopping_mode_sessions'::regclass,
    'public.tasks'::regclass,
    'public.expenses'::regclass,
    'public.inventory_items'::regclass,
    'public.notifications'::regclass,
    'public.invitations'::regclass
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
