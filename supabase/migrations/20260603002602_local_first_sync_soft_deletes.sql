-- Local-first sync must see soft-deleted rows in updated_at checks.
-- Display queries still filter deleted_at, but sync cursors need deletion events
-- to move forward so clients can hide locally cached rows deleted elsewhere.
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
    'shopping_lists', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.shopping_lists
      WHERE home_id = p_home_id
    ),
    'shopping_items', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.shopping_items
      WHERE home_id = p_home_id
    ),
    'tasks', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.tasks
      WHERE home_id = p_home_id
    ),
    'inventory_items', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.inventory_items
      WHERE home_id = p_home_id
    ),
    'expenses', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.expenses
      WHERE home_id = p_home_id
    ),
    'categories', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamptz)
      FROM public.categories
      WHERE home_id = p_home_id
    )
  );

  RETURN v_result;
END;
$$;
