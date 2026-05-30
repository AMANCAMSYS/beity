-- Expenses Phase Database Contract
-- Feature: 014-expenses-phase
-- Date: 2026-05-13

-- ============================================================
-- TABLES
-- ============================================================

-- Expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
  amount integer NOT NULL CHECK (amount > 0),
  description text NOT NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  paid_by uuid NOT NULL REFERENCES auth.users(id),
  shopping_list_item_id uuid REFERENCES shopping_items(id) ON DELETE SET NULL,
  currency_code varchar(3) NOT NULL DEFAULT 'SAR',
  converted_amount integer NOT NULL CHECK (converted_amount > 0),
  status varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled')),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id),
  cancelled_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Expense splits table
CREATE TABLE IF NOT EXISTS expense_splits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id uuid NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
  member_id uuid NOT NULL REFERENCES auth.users(id),
  amount integer NOT NULL CHECK (amount >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(expense_id, member_id)
);

-- Settlements table
CREATE TABLE IF NOT EXISTS settlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
  from_member uuid NOT NULL REFERENCES auth.users(id),
  to_member uuid NOT NULL REFERENCES auth.users(id),
  amount integer NOT NULL CHECK (amount > 0),
  payment_method varchar(50) NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'transfer', 'other')),
  date date NOT NULL DEFAULT CURRENT_DATE,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (from_member != to_member)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_expenses_home_id ON expenses(home_id);
CREATE INDEX idx_expenses_paid_by ON expenses(paid_by);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_category_id ON expenses(category_id);
CREATE INDEX idx_expenses_status ON expenses(status) WHERE deleted_at IS NULL;

CREATE INDEX idx_expense_splits_expense_id ON expense_splits(expense_id);
CREATE INDEX idx_expense_splits_member_id ON expense_splits(member_id);

CREATE INDEX idx_settlements_home_id ON settlements(home_id);
CREATE INDEX idx_settlements_from_member ON settlements(from_member);
CREATE INDEX idx_settlements_to_member ON settlements(to_member);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;

-- Expenses policies
CREATE POLICY "Members can view home expenses"
  ON expenses FOR SELECT
  USING (home_id IN (
    SELECT home_id FROM home_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Members can insert expenses"
  ON expenses FOR INSERT
  WITH CHECK (home_id IN (
    SELECT home_id FROM home_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Members can update home expenses"
  ON expenses FOR UPDATE
  USING (home_id IN (
    SELECT home_id FROM home_members WHERE user_id = auth.uid()
  ));

-- Expense splits policies
CREATE POLICY "Members can view expense splits"
  ON expense_splits FOR SELECT
  USING (expense_id IN (
    SELECT id FROM expenses WHERE home_id IN (
      SELECT home_id FROM home_members WHERE user_id = auth.uid()
    )
  ));

CREATE POLICY "Members can insert expense splits"
  ON expense_splits FOR INSERT
  WITH CHECK (expense_id IN (
    SELECT id FROM expenses WHERE home_id IN (
      SELECT home_id FROM home_members WHERE user_id = auth.uid()
    )
  ));

CREATE POLICY "Members can update expense splits"
  ON expense_splits FOR UPDATE
  USING (expense_id IN (
    SELECT id FROM expenses WHERE home_id IN (
      SELECT home_id FROM home_members WHERE user_id = auth.uid()
    )
  ));

CREATE POLICY "Members can delete expense splits"
  ON expense_splits FOR DELETE
  USING (expense_id IN (
    SELECT id FROM expenses WHERE home_id IN (
      SELECT home_id FROM home_members WHERE user_id = auth.uid()
    )
  ));

-- Settlements policies
CREATE POLICY "Members can view home settlements"
  ON settlements FOR SELECT
  USING (home_id IN (
    SELECT home_id FROM home_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Members can insert settlements"
  ON settlements FOR INSERT
  WITH CHECK (home_id IN (
    SELECT home_id FROM home_members WHERE user_id = auth.uid()
  ));

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Create an expense and its splits atomically
CREATE OR REPLACE FUNCTION create_expense_with_splits(
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
  v_expense expenses%ROWTYPE;
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
    FROM home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = v_user_id
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM home_members hm
    WHERE hm.home_id = p_home_id
      AND hm.user_id = p_paid_by
      AND hm.status = 'active'
      AND hm.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Payer must be an active member of the home';
  END IF;

  IF p_category_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM categories c
    WHERE c.id = p_category_id
      AND c.type = 'expense'
      AND c.deleted_at IS NULL
      AND (c.is_default = true OR c.home_id = p_home_id)
  ) THEN
    RAISE EXCEPTION 'Expense category must belong to the home or be a default expense category';
  END IF;

  IF p_shopping_list_item_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM shopping_items si
    JOIN shopping_lists sl ON sl.id = si.list_id
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
        FROM home_members hm
        WHERE hm.home_id = p_home_id
          AND hm.user_id = split.member_id
          AND hm.status = 'active'
          AND hm.deleted_at IS NULL
      )
    ) THEN
      RAISE EXCEPTION 'Split member must be an active member of the home';
    END IF;
  END IF;

  INSERT INTO expenses (
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
    INSERT INTO expense_splits (expense_id, member_id, amount)
    SELECT v_expense.id, split.member_id, split.amount
    FROM jsonb_to_recordset(p_splits) AS split(member_id uuid, amount integer);
  END IF;

  RETURN to_jsonb(v_expense);
END;
$$;

-- Calculate net balances for a home
CREATE OR REPLACE FUNCTION calculate_home_balances(p_home_id uuid)
RETURNS TABLE (
  member_a uuid,
  member_b uuid,
  net_amount integer
)
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
    FROM home_members hm
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
    FROM expense_splits es
    JOIN expenses e ON e.id = es.expense_id
    WHERE e.home_id = p_home_id
      AND e.status = 'active'
      AND e.deleted_at IS NULL
      AND es.member_id <> e.paid_by

    UNION ALL

    SELECT
      s.from_member AS debtor,
      s.to_member AS creditor,
      (-s.amount)::integer AS amount
    FROM settlements s
    WHERE s.home_id = p_home_id
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

-- Check if member has unsettled balances
CREATE OR REPLACE FUNCTION has_unsettled_balances(p_home_id uuid, p_user_id uuid)
RETURNS boolean AS $$
DECLARE
  has_balance boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM calculate_home_balances(p_home_id)
    WHERE member_a = p_user_id OR member_b = p_user_id
  ) INTO has_balance;
  
  RETURN has_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update updated_at on expenses
CREATE OR REPLACE FUNCTION update_expenses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_expenses_updated_at();
