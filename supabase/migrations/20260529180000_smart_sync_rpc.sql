-- SQL Migration: Add unified get_tables_last_update RPC function for Smart Sync
-- Created at: 2026-05-29

CREATE OR REPLACE FUNCTION public.get_tables_last_update(p_home_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  v_result := jsonb_build_object(
    'shopping_lists', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamp) 
      FROM public.shopping_lists 
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'shopping_items', (
      SELECT COALESCE(MAX(i.updated_at), '1970-01-01'::timestamp) 
      FROM public.shopping_items i 
      JOIN public.shopping_lists l ON i.list_id = l.id 
      WHERE l.home_id = p_home_id AND i.deleted_at IS NULL
    ),
    'tasks', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamp) 
      FROM public.tasks 
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'inventory_items', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamp) 
      FROM public.inventory_items 
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'expenses', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamp) 
      FROM public.expenses 
      WHERE home_id = p_home_id AND deleted_at IS NULL
    ),
    'categories', (
      SELECT COALESCE(MAX(updated_at), '1970-01-01'::timestamp) 
      FROM public.categories 
      WHERE home_id = p_home_id AND deleted_at IS NULL
    )
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.get_tables_last_update(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_tables_last_update(UUID) TO service_role;
