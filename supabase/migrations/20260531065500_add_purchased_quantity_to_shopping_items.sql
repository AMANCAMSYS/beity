-- Add purchased_quantity to shopping_items table
ALTER TABLE "public"."shopping_items" 
ADD COLUMN IF NOT EXISTS "purchased_quantity" numeric(10,2) DEFAULT 0 NOT NULL;

-- Backfill existing completed items
UPDATE "public"."shopping_items"
SET "purchased_quantity" = "quantity"
WHERE "status" = 'completed' AND "purchased_quantity" = 0;
