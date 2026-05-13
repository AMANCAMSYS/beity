# Research: Expenses Phase

**Feature**: 014-expenses-phase
**Date**: 2026-05-13

## Research Tasks

### 1. Expense Splitting Algorithms

**Decision**: Implement two split modes — equal split and custom split.

**Rationale**:
- Equal split: Divide amount by number of selected members, handle rounding by assigning remainder to the payer
- Custom split: User enters exact amounts per member, system validates total equals expense amount
- Single-member split treated as personal expense (no split record created)

**Alternatives Considered**:
- Percentage-based split: More complex UI, less intuitive for households
- Share-based split (e.g., 2 shares, 1 share): Overcomplicates simple home use case

**Implementation Notes**:
- Rounding strategy: Smallest currency unit (e.g., cents), remainder assigned to payer
- Validation: Sum of splits must equal expense amount ± 1 cent (floating point tolerance)

---

### 2. Balance Calculation Algorithm

**Decision**: Real-time calculation using net-balance approach with graph simplification.

**Rationale**:
- Calculate net balance for each member pair from all active expenses and settlements
- Simplify debt graph: if A owes B $30 and B owes A $10, show only A owes B $20
- No materialized/cached balances — compute on-demand for accuracy

**Alternatives Considered**:
- Materialized balance table: Faster reads but requires sync logic, risk of stale data
- Transaction-chain approach: Shows every debt individually, confusing for users

**Implementation Notes**:
- Query all expense_splits for home where member is involved
- Query all settlements for home where member is involved
- Net balance = sum(owed) - sum(paid) - sum(settlements_received) + sum(settlements_made)
- Use Supabase RPC (PostgreSQL function) for efficient calculation

---

### 3. Supabase Realtime for Expenses

**Decision**: Use Supabase Realtime subscriptions on `expenses` and `settlements` tables.

**Rationale**:
- Leverages existing Supabase Realtime infrastructure from shopping list feature
- Changes broadcast to all home members automatically
- Consistent with project's realtime collaboration principle

**Alternatives Considered**:
- Polling: Wastes bandwidth, slower updates
- Firebase Realtime: Inconsistent with Supabase-first architecture

**Implementation Notes**:
- Subscribe to `expenses` table filtered by `home_id`
- Subscribe to `settlements` table filtered by `home_id`
- Handle INSERT, UPDATE, DELETE events
- Unsubscribe on screen dispose

---

### 4. RLS Policies for Expense Tables

**Decision**: Implement RLS policies ensuring home membership is verified for all operations.

**Rationale**:
- Aligns with constitution principle: "Users can only access data where they are active members"
- Prevents cross-home data leakage
- Consistent with existing RLS patterns in shopping list feature

**Alternatives Considered**:
- Application-level auth only: Violates RLS-first principle
- API-level checks: Insufficient, database must enforce

**Implementation Notes**:
```sql
-- expenses table
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

-- Similar for UPDATE, DELETE, and settlements table
```

---

### 5. Member Departure with Unsettled Balances

**Decision**: Block member departure if unsettled balances exist.

**Rationale**:
- Prevents financial disputes and data integrity issues
- User sees exact unsettled amounts before attempting to leave
- Encourages settlement before departure

**Alternatives Considered**:
- Forgive balances: Unfair to creditors
- Freeze balances: Leaves unresolved debts
- Transfer balances: Complex redistribution logic

**Implementation Notes**:
- Before allowing departure, call balance calculation RPC
- If any balance ≠ 0, return error with unsettled amounts
- UI shows "Settle $X with Y before leaving" message

---

### 6. Soft Delete for Expenses

**Decision**: Use `deleted_at` timestamp column for soft deletion.

**Rationale**:
- Preserves audit trail as required by spec clarification
- Settlements remain intact after expense deletion
- Consistent with constitution's soft-delete pattern

**Alternatives Considered**:
- Hard delete: Loses audit trail, breaks settlement references
- Status field only: Less standard, harder to query

**Implementation Notes**:
- Add `deleted_at` column to `expenses` table (nullable)
- Query filters: `WHERE deleted_at IS NULL` by default
- UI shows cancelled expenses differently (grayed out, "Cancelled" badge)
- Settlements linked to cancelled expenses remain visible

---

## Technology Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Split modes | Equal + Custom | Covers 95% of household use cases |
| Balance calculation | Real-time net-balance | Always accurate, no sync issues |
| Realtime | Supabase Realtime | Consistent with existing architecture |
| RLS | Home membership check | Constitution requirement |
| Member departure | Block until settled | Prevents disputes |
| Soft delete | `deleted_at` pattern | Audit trail preservation |
