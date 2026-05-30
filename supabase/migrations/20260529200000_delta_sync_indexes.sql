-- SQL Migration: Add high-performance indexes for Local-First Delta Sync
-- Created at: 2026-05-29

BEGIN;

-- Shopping lists: composite index for fast home lookup and updated_at scanning
CREATE INDEX IF NOT EXISTS idx_shopping_lists_delta_sync
ON public.shopping_lists (home_id, updated_at DESC);

-- Shopping items: composite index for fast list lookup and updated_at scanning
CREATE INDEX IF NOT EXISTS idx_shopping_items_delta_sync
ON public.shopping_items (list_id, updated_at DESC);

-- Tasks: composite index for fast home lookup and updated_at scanning
CREATE INDEX IF NOT EXISTS idx_tasks_delta_sync
ON public.tasks (home_id, updated_at DESC);

-- Expenses: composite index for fast home lookup and updated_at scanning
CREATE INDEX IF NOT EXISTS idx_expenses_delta_sync
ON public.expenses (home_id, updated_at DESC);

-- Inventory items: composite index for fast home lookup and updated_at scanning
CREATE INDEX IF NOT EXISTS idx_inventory_items_delta_sync
ON public.inventory_items (home_id, updated_at DESC);

-- Categories: composite index for fast home lookup and updated_at scanning
CREATE INDEX IF NOT EXISTS idx_categories_delta_sync
ON public.categories (home_id, updated_at DESC);

COMMIT;
