-- =============================================================
-- Expense Split Integrity
-- =============================================================
-- Adds an atomic RPC for creating an expense with its splits and
-- fixes balance simplification so payer self-shares are ignored.
-- =============================================================

BEGIN;

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS cancelled_by uuid REFERENCES auth.users(id);

DROP FUNCTION IF EXISTS public.create_expense_with_splits(
  uuid,
  integer,
  text,
  date,
  uuid,
  integer,
  uuid,
  uuid,
  text,
  jsonb
);

CREATE OR REPLACE FUNCTION public.create_expense_with_splits(
  p_home_id uuid,
  p_amount integer,
  p_description text,
  p_date date,
  p_paid_by uuid,
  p_converted_amount integer,
  p_category_id uuid DEFAULT NULL,
  p_shopping_list_item_id uuid DEFAULT NULL,
  p_currency_code text DEFAULT 'SAR',
  p_splits jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_expense public.expenses%ROWTYPE;
  v_split_count integer := 0;
  v_distinct_member_count integer := 0;
  v_split_total integer := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_amount <= 0 OR p_converted_amount <= 0 THEN
    RAISE EXCEPTION 'Expense amount must be greater than zero';
  END IF;

  IF trim(coalesce(p_description, '')) = '' THEN
    RAISE EXCEPTION 'Expense description is required';
  END IF;

  IF length(trim(coalesce(p_currency_code, ''))) <> 3 THEN
    RAISE EXCEPTION 'Currency code must be 3 characters';
  END IF;

  IF p_splits IS NULL THEN
    p_splits := '[]'::jsonb;
  END IF;

  IF jsonb_typeof(p_splits) <> 'array' THEN
    RAISE EXCEPTION 'Splits must be a JSON array';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = v_user_id
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = p_paid_by
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Payer must be an active member of the home';
  END IF;

  IF p_category_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.categories c
    WHERE c.id = p_category_id
      AND c.type = 'expense'
      AND c.deleted_at IS NULL
      AND (c.is_default = true OR c.home_id = p_home_id)
  ) THEN
    RAISE EXCEPTION 'Expense category must belong to the home or be a default expense category';
  END IF;

  IF p_shopping_list_item_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.shopping_items si
    JOIN public.shopping_lists sl ON sl.id = si.list_id
    WHERE si.id = p_shopping_list_item_id
      AND si.deleted_at IS NULL
      AND sl.home_id = p_home_id
      AND sl.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Shopping list item must belong to the home';
  END IF;

  WITH split_rows AS (
    SELECT member_id, amount
    FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer)
  )
  SELECT
    count(*)::integer,
    count(DISTINCT member_id)::integer,
    coalesce(sum(amount), 0)::integer
  INTO v_split_count, v_distinct_member_count, v_split_total
  FROM split_rows;

  IF v_split_count > 0 THEN
    IF v_distinct_member_count <> v_split_count THEN
      RAISE EXCEPTION 'Split members must be unique';
    END IF;

    IF v_split_total <> p_converted_amount THEN
      RAISE EXCEPTION 'Split total must equal converted expense amount';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer)
      WHERE split.member_id IS NULL OR split.amount IS NULL OR split.amount < 0
    ) THEN
      RAISE EXCEPTION 'Each split must have a member and non-negative amount';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer)
      WHERE NOT EXISTS (
        SELECT 1
        FROM public.home_members hm
        WHERE hm.home_id = p_home_id
          AND hm.user_id = split.member_id
          AND hm.status = 'active'
          AND hm.deleted_at IS NULL
      )
    ) THEN
      RAISE EXCEPTION 'Split member must be an active member of the home';
    END IF;
  END IF;

  INSERT INTO public.expenses (
    home_id,
    amount,
    description,
    date,
    category_id,
    paid_by,
    shopping_list_item_id,
    currency_code,
    converted_amount,
    created_by
  )
  VALUES (
    p_home_id,
    p_amount,
    trim(p_description),
    p_date,
    p_category_id,
    p_paid_by,
    p_shopping_list_item_id,
    upper(trim(p_currency_code)),
    p_converted_amount,
    v_user_id
  )
  RETURNING * INTO v_expense;

  IF v_split_count > 1 THEN
    INSERT INTO public.expense_splits (expense_id, member_id, amount)
    SELECT v_expense.id, split.member_id, split.amount
    FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer);
  END IF;

  RETURN to_jsonb(v_expense);
END;
$$;

REVOKE ALL ON FUNCTION public.create_expense_with_splits(
  uuid,
  integer,
  text,
  date,
  uuid,
  integer,
  uuid,
  uuid,
  text,
  jsonb
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.create_expense_with_splits(
  uuid,
  integer,
  text,
  date,
  uuid,
  integer,
  uuid,
  uuid,
  text,
  jsonb
) TO authenticated;

CREATE OR REPLACE FUNCTION public.calculate_home_balances(p_home_id uuid)
RETURNS TABLE(member_a uuid, member_b uuid, net_amount integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = auth.uid()
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  WITH movements AS (
    SELECT
      es.member_id AS debtor,
      e.paid_by AS creditor,
      es.amount::integer AS amount
    FROM public.expense_splits es
    JOIN public.expenses e ON e.id = es.expense_id
    WHERE e.home_id = p_home_id
      AND e.status = 'active'
      AND e.deleted_at IS NULL
      AND es.member_id <> e.paid_by

    UNION ALL

    SELECT
      s.from_member AS debtor,
      s.to_member AS creditor,
      (-s.amount)::integer AS amount
    FROM public.settlements s
    WHERE s.home_id = p_home_id
      AND s.from_member <> s.to_member
  ),
  canonical_pairs AS (
    SELECT
      CASE WHEN debtor::text < creditor::text THEN debtor ELSE creditor END AS member_low,
      CASE WHEN debtor::text < creditor::text THEN creditor ELSE debtor END AS member_high,
      CASE WHEN debtor::text < creditor::text THEN amount ELSE -amount END AS signed_amount
    FROM movements
  ),
  simplified AS (
    SELECT
      member_low,
      member_high,
      sum(signed_amount)::integer AS signed_amount
    FROM canonical_pairs
    GROUP BY member_low, member_high
  )
  SELECT
    CASE WHEN signed_amount > 0 THEN member_low ELSE member_high END AS member_a,
    CASE WHEN signed_amount > 0 THEN member_high ELSE member_low END AS member_b,
    abs(signed_amount)::integer AS net_amount
  FROM simplified
  WHERE signed_amount <> 0;
END;
$$;

REVOKE ALL ON FUNCTION public.calculate_home_balances(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_home_balances(uuid) TO authenticated;

COMMIT;
