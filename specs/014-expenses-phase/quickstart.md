# Quickstart: Expenses Phase

**Feature**: 014-expenses-phase
**Date**: 2026-05-13

## Overview

This guide helps developers quickly understand and start working on the Expenses feature.

## Prerequisites

- Beity project set up with Flutter and Supabase
- Familiarity with feature-first clean architecture
- Understanding of existing features (SPEC 01-04)

## Key Concepts

### 1. Expense Model

An expense represents a household purchase with:
- **Amount**: Stored in smallest currency unit (cents) as integer
- **Currency**: Original currency code + converted amount in home's base currency
- **Status**: `active` or `cancelled` (soft delete)
- **Splits**: Who owes how much of this expense

### 2. Split Types

- **Equal split**: Amount divided evenly among selected members, remainder to payer
- **Custom split**: User specifies exact amounts per member
- **Personal expense**: Single member, no split record

### 3. Balance Calculation

Balances are calculated in real-time:
```
Net Balance = Sum(owed from splits) - Sum(settlements received)
```

If A owes B $30 and B owes A $10, net balance shows A owes B $20.

### 4. Settlement

A settlement records a payment between members:
- **From**: Who paid
- **To**: Who received
- **Amount**: Payment amount
- **Method**: Cash, transfer, or other

## Implementation Steps

### Step 1: Database Migration

Run the SQL contract from `contracts/database.sql`:
- Creates `expenses`, `expense_splits`, `settlements` tables
- Sets up RLS policies for home membership isolation
- Creates `calculate_home_balances()` and `has_unsettled_balances()` RPC functions

### Step 2: Domain Layer

Create entities and repository interfaces:
```dart
// lib/features/expenses/domain/entities/expense.dart
class Expense {
  final String id;
  final String homeId;
  final int amount; // cents
  final String description;
  final DateTime date;
  final String? categoryId;
  final String paidBy;
  final String? shoppingListItemId;
  final String currencyCode;
  final int convertedAmount;
  final String status; // 'active' or 'cancelled'
  // ...
}
```

### Step 3: Data Layer

Implement repositories with Supabase datasource:
- Use `supabase.from('expenses')` for CRUD
- Use `supabase.rpc('calculate_home_balances')` for balances
- Handle realtime subscriptions for live updates

### Step 4: Presentation Layer

Build screens with Riverpod providers:
- `ExpenseListScreen`: Shows expenses with filters
- `AddExpenseScreen`: Form with split selector
- `BalancesScreen`: Shows who owes whom
- `SettlementScreen`: Record payments

## Testing Checklist

- [ ] Add expense with equal split
- [ ] Add expense with custom split
- [ ] Edit expense and verify splits recalculated
- [ ] Soft-delete expense and verify balances unchanged
- [ ] Record settlement and verify balance updated
- [ ] Verify RTL layout works correctly
- [ ] Verify realtime updates for other members

## Common Pitfalls

1. **Rounding errors**: Use integer math (cents), assign remainder to payer
2. **Soft delete**: Always filter `WHERE deleted_at IS NULL` in queries
3. **Balance calculation**: Must include only `active` expenses
4. **RLS**: All queries must go through Supabase client (not raw SQL)
5. **Realtime**: Subscribe on screen mount, unsubscribe on dispose

## References

- [Spec](./spec.md) — Feature requirements
- [Data Model](./data-model.md) — Entity definitions
- [Database Contract](./contracts/database.sql) — SQL schema
