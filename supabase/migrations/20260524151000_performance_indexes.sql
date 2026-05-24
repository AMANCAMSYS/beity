-- =============================================================
-- Performance Indexes
-- =============================================================

BEGIN;

-- Home members: fast lookup for active membership checks (most RLS policies use this)
CREATE INDEX IF NOT EXISTS idx_home_members_active_user_home
ON public.home_members (user_id, home_id)
WHERE status = 'active' AND deleted_at IS NULL;

-- Shopping lists: fast lookup by home, sorted by recent updates
CREATE INDEX IF NOT EXISTS idx_shopping_lists_home_active
ON public.shopping_lists (home_id, updated_at DESC)
WHERE deleted_at IS NULL;

-- Shopping items: fast lookup by list, sorted by recent updates
CREATE INDEX IF NOT EXISTS idx_shopping_items_list_active
ON public.shopping_items (list_id, updated_at DESC)
WHERE deleted_at IS NULL;

-- Invitations: fast lookup by email and status
CREATE INDEX IF NOT EXISTS idx_invitations_email_status
ON public.invitations (lower(email), status, expires_at);

-- Invitations: fast lookup by home and status
CREATE INDEX IF NOT EXISTS idx_invitations_home_status
ON public.invitations (home_id, status, created_at DESC);

-- Notifications: fast lookup for unread notifications per user
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread_created
ON public.notifications (user_id, is_read, created_at DESC);

-- Products: fast lookup by home
CREATE INDEX IF NOT EXISTS idx_products_home
ON public.products (home_id)
WHERE deleted_at IS NULL;

-- Fix inventory unique index to prevent duplicate active items
-- First drop the constraint that depends on the index
ALTER TABLE public.inventory_items
  DROP CONSTRAINT IF EXISTS uq_inventory_items_home_name_unit;

DROP INDEX IF EXISTS public.uq_inventory_items_home_name_unit;

CREATE UNIQUE INDEX IF NOT EXISTS uq_inventory_items_active_home_name_unit
ON public.inventory_items (home_id, lower(name), unit_id)
WHERE deleted_at IS NULL;

COMMIT;
