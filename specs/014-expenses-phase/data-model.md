# Data Model: Expenses Phase

**Feature**: 014-expenses-phase
**Date**: 2026-05-13

## Entities

### expenses

Represents a purchase made for the household.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | no | gen_random_uuid() | Primary key |
| home_id | uuid | no | — | Foreign key to homes table |
| amount | integer | no | — | Amount in smallest currency unit (cents) |
| description | text | no | — | Expense description |
| date | date | no | CURRENT_DATE | Date of expense |
| category_id | uuid | yes | null | Foreign key to categories table |
| paid_by | uuid | no | — | Foreign key to auth.users (who paid) |
| shopping_list_item_id | uuid | yes | null | Foreign key to shopping_items table |
| currency_code | varchar(3) | no | 'SAR' | Currency code (ISO 4217) |
| converted_amount | integer | no | — | Amount in home's base currency (cents) |
| status | varchar(20) | no | 'active' | Status: active or cancelled |
| created_by | uuid | no | — | Foreign key to auth.users |
| created_at | timestamptz | no | now() | Creation timestamp |
| updated_at | timestamptz | no | now() | Last update timestamp |
| deleted_at | timestamptz | yes | null | Soft delete timestamp |

**Constraints**:
- `amount > 0`
- `status IN ('active', 'cancelled')`
- `currency_code` must be valid ISO 4217
- `converted_amount > 0`

**Indexes**:
- `idx_expenses_home_id` on `home_id`
- `idx_expenses_paid_by` on `paid_by`
- `idx_expenses_date` on `date`
- `idx_expenses_category_id` on `category_id`
- `idx_expenses_status` on `status` (partial, WHERE deleted_at IS NULL)

**RLS Policies**:
- SELECT: Home members only
- INSERT: Home members only
- UPDATE: Home members only (own expenses or home owner)
- DELETE: Soft delete only (set deleted_at)

---

### expense_splits

Represents a member's share of an expense.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | no | gen_random_uuid() | Primary key |
| expense_id | uuid | no | — | Foreign key to expenses table |
| member_id | uuid | no | — | Foreign key to auth.users |
| amount | integer | no | — | Amount owed in smallest currency unit |
| created_at | timestamptz | no | now() | Creation timestamp |

**Constraints**:
- `amount >= 0`
- Unique constraint on `(expense_id, member_id)`

**Indexes**:
- `idx_expense_splits_expense_id` on `expense_id`
- `idx_expense_splits_member_id` on `member_id`

**RLS Policies**:
- SELECT: Home members only (via expense's home_id)
- INSERT: Home members only
- UPDATE: Home members only
- DELETE: Home members only

**Notes**:
- If only one member in split, treat as personal expense (no split record)
- Sum of splits must equal expense's converted_amount

---

### settlements

Represents a payment between members to settle debts.

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | uuid | no | gen_random_uuid() | Primary key |
| home_id | uuid | no | — | Foreign key to homes table |
| from_member | uuid | no | — | Foreign key to auth.users (who paid) |
| to_member | uuid | no | — | Foreign key to auth.users (who received) |
| amount | integer | no | — | Amount in smallest currency unit |
| payment_method | varchar(50) | no | 'cash' | Payment method: cash, transfer, other |
| date | date | no | CURRENT_DATE | Date of settlement |
| created_by | uuid | no | — | Foreign key to auth.users |
| created_at | timestamptz | no | now() | Creation timestamp |

**Constraints**:
- `amount > 0`
- `from_member != to_member`
- `payment_method IN ('cash', 'transfer', 'other')`

**Indexes**:
- `idx_settlements_home_id` on `home_id`
- `idx_settlements_from_member` on `from_member`
- `idx_settlements_to_member` on `to_member`

**RLS Policies**:
- SELECT: Home members only
- INSERT: Home members only
- UPDATE: Home members only (own settlements or home owner)
- DELETE: Home members only (own settlements or home owner)

---

## Relationships

```mermaid
erDiagram
    homes ||--o{ expenses : has
    homes ||--o{ settlements : has
    expenses ||--o{ expense_splits : has
    categories ||--o{ expenses : categorizes
    shopping_items ||--o| expenses : links
    auth.users ||--o{ expenses : pays
    auth.users ||--o{ expense_splits : owes
    auth.users ||--o{ settlements : from
    auth.users ||--o{ settlements : to
```

---

## Balance Calculation

Balances are calculated in real-time using the following logic:

```sql
-- For a given home, calculate net balance between all member pairs
WITH expense_debts AS (
  -- What each member owes from expense splits
  SELECT 
    es.member_id as debtor,
    e.paid_by as creditor,
    SUM(es.amount) as total_owed
  FROM expense_splits es
  JOIN expenses e ON e.id = es.expense_id
  WHERE e.home_id = :home_id 
    AND e.status = 'active'
    AND e.deleted_at IS NULL
  GROUP BY es.member_id, e.paid_by
),
settlement_credits AS (
  -- Settlements received
  SELECT 
    from_member as debtor,
    to_member as creditor,
    SUM(amount) as total_settled
  FROM settlements
  WHERE home_id = :home_id
  GROUP BY from_member, to_member
),
net_balances AS (
  SELECT 
    debtor,
    creditor,
    COALESCE(total_owed, 0) - COALESCE(total_settled, 0) as net_amount
  FROM expense_debts
  FULL OUTER JOIN settlement_credits USING (debtor, creditor)
)
SELECT * FROM net_balances WHERE net_amount != 0;
```

---

## State Transitions

### Expense Status
```
active → cancelled (soft delete)
```
- Only `active` expenses contribute to balance calculations
- `cancelled` expenses retain all data for audit purposes
- Settlements linked to cancelled expenses remain intact

### Settlement Lifecycle
- Settlements are immutable once created
- No edit or delete allowed (financial integrity)
- Corrections made by creating offsetting settlements
