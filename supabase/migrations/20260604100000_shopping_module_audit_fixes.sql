-- Fix PP-1: Update check constraint to allow 'in_progress' for partial purchases
ALTER TABLE public.shopping_items DROP CONSTRAINT IF EXISTS shopping_items_status_check;
ALTER TABLE public.shopping_items ADD CONSTRAINT shopping_items_status_check 
  CHECK (status = ANY (ARRAY['pending', 'in_progress', 'completed', 'cancelled']));

-- Fix RLS-1: Viewers should not be able to update shopping lists
DROP POLICY IF EXISTS "Home members can update lists" ON public.shopping_lists;
CREATE POLICY "Home members can update lists" ON public.shopping_lists FOR UPDATE 
  USING (is_not_viewer(home_id)) 
  WITH CHECK (is_not_viewer(home_id));
