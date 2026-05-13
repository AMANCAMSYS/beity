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

-- Calculate net balances for a home
CREATE OR REPLACE FUNCTION calculate_home_balances(p_home_id uuid)
RETURNS TABLE (
  member_a uuid,
  member_b uuid,
  net_amount integer
) AS $$
BEGIN
  RETURN QUERY
  WITH expense_debts AS (
    SELECT 
      es.member_id as debtor,
      e.paid_by as creditor,
      SUM(es.amount) as total_owed
    FROM expense_splits es
    JOIN expenses e ON e.id = es.expense_id
    WHERE e.home_id = p_home_id 
      AND e.status = 'active'
      AND e.deleted_at IS NULL
    GROUP BY es.member_id, e.paid_by
  ),
  settlement_credits AS (
    SELECT 
      s.from_member as debtor,
      s.to_member as creditor,
      SUM(s.amount) as total_settled
    FROM settlements s
    WHERE s.home_id = p_home_id
    GROUP BY s.from_member, s.to_member
  ),
  all_pairs AS (
    SELECT debtor, creditor FROM expense_debts
    UNION
    SELECT debtor, creditor FROM settlement_credits
  ),
  net_balances AS (
    SELECT 
      ap.debtor,
      ap.creditor,
      COALESCE(ed.total_owed, 0) - COALESCE(sc.total_settled, 0) as net_amount
    FROM all_pairs ap
    LEFT JOIN expense_debts ed ON ed.debtor = ap.debtor AND ed.creditor = ap.creditor
    LEFT JOIN settlement_credits sc ON sc.debtor = ap.debtor AND sc.creditor = ap.creditor
  )
  SELECT 
    nb.debtor as member_a,
    nb.creditor as member_b,
    nb.net_amount
  FROM net_balances nb
  WHERE nb.net_amount != 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
