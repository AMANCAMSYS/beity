-- Add inventory_transferred_at column to shopping_lists
ALTER TABLE "public"."shopping_lists"
ADD COLUMN IF NOT EXISTS "inventory_transferred_at" timestamp with time zone;

DROP FUNCTION IF EXISTS "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid");

-- Update the RPC to accept p_list_id and enforce idempotency
CREATE OR REPLACE FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid", "p_list_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_item record;
  v_name text;
  v_quantity numeric;
  v_unit_id uuid;
  v_category_id uuid;
  v_existing_id uuid;
  v_existing_qty numeric;
  v_user_id uuid;
  v_list_id uuid;
  v_items_count integer := 0;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_not_viewer(p_home_id) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF p_list_id IS NULL THEN
    RAISE EXCEPTION 'Missing shopping list id';
  END IF;

  UPDATE public.shopping_lists
  SET inventory_transferred_at = NOW(),
      status = 'archived',
      updated_at = NOW(),
      updated_by = v_user_id
  WHERE id = p_list_id
    AND home_id = p_home_id
    AND deleted_at IS NULL
    AND status IN ('active', 'completed')
    AND inventory_transferred_at IS NULL
  RETURNING id INTO v_list_id;

  IF v_list_id IS NULL THEN
    RAISE EXCEPTION 'List is not transferable';
  END IF;

  FOR v_item IN
    SELECT
      si.name,
      CASE
        WHEN si.purchased_quantity > 0 THEN si.purchased_quantity
        ELSE si.quantity
      END AS quantity,
      si.unit_id,
      si.category_id
    FROM public.shopping_items si
    WHERE si.list_id = p_list_id
      AND si.home_id = p_home_id
      AND si.deleted_at IS NULL
      AND (si.status = 'completed' OR si.purchased_quantity > 0)
  LOOP
    v_items_count := v_items_count + 1;
    v_name := v_item.name;
    v_quantity := v_item.quantity;
    v_unit_id := v_item.unit_id;
    v_category_id := v_item.category_id;

    IF v_quantity <= 0 THEN
      CONTINUE;
    END IF;

    LOOP
      UPDATE public.inventory_items
      SET quantity = quantity + v_quantity,
          updated_by = v_user_id
      WHERE home_id = p_home_id
        AND lower(name) = lower(v_name)
        AND unit_id IS NOT DISTINCT FROM v_unit_id
        AND deleted_at IS NULL
      RETURNING id, quantity INTO v_existing_id, v_existing_qty;
      IF FOUND THEN
        INSERT INTO public.inventory_transactions (
          inventory_item_id, home_id, previous_quantity, new_quantity, change_reason, changed_by
        ) VALUES (
          v_existing_id, p_home_id, v_existing_qty - v_quantity, v_existing_qty, 'shopping_restock', v_user_id
        );
        EXIT;
      END IF;
      BEGIN
        INSERT INTO public.inventory_items (
          home_id, name, quantity, unit_id, category_id, created_by, updated_by
        ) VALUES (
          p_home_id, v_name, v_quantity, v_unit_id, v_category_id, v_user_id, v_user_id
        ) RETURNING id INTO v_existing_id;
        INSERT INTO public.inventory_transactions (
          inventory_item_id, home_id, previous_quantity, new_quantity, change_reason, changed_by
        ) VALUES (
          v_existing_id, p_home_id, 0, v_quantity, 'shopping_restock', v_user_id
        );
        EXIT;
      EXCEPTION WHEN unique_violation THEN
      END;
    END LOOP;
  END LOOP;

  IF v_items_count = 0 THEN
    RAISE EXCEPTION 'No purchased items to transfer';
  END IF;
END;
$$;

ALTER FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid", "p_list_id" "uuid") OWNER TO "postgres";

REVOKE ALL ON FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid", "p_list_id" "uuid") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid", "p_list_id" "uuid") TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid", "p_list_id" "uuid") TO "service_role";

DROP POLICY IF EXISTS "Home members can update lists" ON "public"."shopping_lists";
CREATE POLICY "Home members can update lists" ON "public"."shopping_lists"
FOR UPDATE
USING ("public"."is_not_viewer"("home_id"))
WITH CHECK ("public"."is_not_viewer"("home_id"));

DROP POLICY IF EXISTS "Users can update own sessions" ON "public"."shopping_mode_sessions";
CREATE POLICY "Users can update own sessions" ON "public"."shopping_mode_sessions"
FOR UPDATE
USING (
  "user_id" = "auth"."uid"()
  AND "home_id" IN (
    SELECT "hm"."home_id"
    FROM "public"."home_members" "hm"
    WHERE "hm"."user_id" = "auth"."uid"()
      AND "hm"."status" = 'active'
      AND "hm"."deleted_at" IS NULL
  )
)
WITH CHECK (
  "user_id" = "auth"."uid"()
  AND "home_id" IN (
    SELECT "hm"."home_id"
    FROM "public"."home_members" "hm"
    WHERE "hm"."user_id" = "auth"."uid"()
      AND "hm"."status" = 'active'
      AND "hm"."deleted_at" IS NULL
  )
);
