# Feature Specification: Expenses Phase

**Feature Branch**: `014-expenses-phase`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "SPEC 14 — Expenses Phase"

## Clarifications

### Session 2026-05-13

- Q: What is the allowed lifecycle for expenses after creation? → A: Editable and soft-deletable — edits allowed, deletion marks as "cancelled" but retains record. Splits recalculated on edit, settlements preserved.
- Q: What should happen to unsettled balances when a member leaves a home? → A: Blocked departure — member cannot leave until balances are settled.
- Q: How should the system handle concurrent edits to the same expense? → A: Last-write-wins — latest edit overwrites, no conflict detection.
- Q: How should balances be calculated and stored? → A: Real-time calculation — balances computed on-demand from expense and settlement records.
- Q: What should happen when a split has only one member remaining? → A: Treat as personal expense — no split recorded, single member pays full amount.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record an Expense (Priority: P1)

As a home member, I want to record an expense I made for the household so that the cost is tracked and can be shared fairly.

**Why this priority**: Recording expenses is the foundation of the expenses feature. Without the ability to log purchases, no other expense functionality delivers value.

**Independent Test**: Can be fully tested by adding an expense with amount, description, and category, then verifying it appears in the expense list.

**Acceptance Scenarios**:

1. **Given** I am a member of a home, **When** I tap "Add Expense" and enter an amount, description, and category, **Then** the expense is saved and visible to all home members
2. **Given** I am recording an expense, **When** I leave the category unselected, **Then** the expense is saved under "Uncategorized"
3. **Given** I am recording an expense, **When** I select a date, **Then** the expense is recorded with that date (defaults to today)
4. **Given** I have an item in my shopping list, **When** I record an expense linked to that item, **Then** the expense is associated with the shopping list item

---

### User Story 2 - View Expense History (Priority: P1)

As a home member, I want to see all expenses for my home so that I can understand where money is being spent.

**Why this priority**: Visibility into spending patterns is the core value proposition of expense tracking.

**Independent Test**: Can be tested by adding multiple expenses and verifying they appear in a list sorted by date with totals.

**Acceptance Scenarios**:

1. **Given** my home has recorded expenses, **When** I open the expenses screen, **Then** I see all expenses listed with date, amount, description, and who paid
2. **Given** I am viewing expenses, **When** I select a date range, **Then** only expenses within that range are shown
3. **Given** I am viewing expenses, **When** I filter by category, **Then** only expenses in that category are shown
4. **Given** I am viewing expenses, **When** I filter by member, **Then** only expenses paid by that member are shown
5. **Given** the home has no expenses, **When** I open the expenses screen, **Then** I see an empty state explaining how to add expenses

---

### User Story 3 - Split Expense Between Members (Priority: P1)

As a home member, I want to split an expense between selected home members so that costs are shared fairly.

**Why this priority**: Expense splitting is the primary reason households track shared expenses — it enables fair cost sharing.

**Independent Test**: Can be tested by creating an expense split between 2+ members and verifying each member's share is calculated correctly.

**Acceptance Scenarios**:

1. **Given** I am recording an expense, **When** I select "Split equally" and choose members, **Then** the expense is divided equally among selected members
2. **Given** I am recording an expense, **When** I select "Split by custom amounts", **Then** I can specify each member's share and the total matches the expense amount
3. **Given** an expense is split, **When** I view the expense details, **Then** I see who owes what amount
4. **Given** I split an expense with myself included, **When** the split is calculated, **Then** my share is included in the split

---

### User Story 4 - Track Balances Between Members (Priority: P2)

As a home member, I want to see who owes whom so that I know the current settlement status within my home.

**Why this priority**: Balance tracking transforms individual expense records into actionable settlement information.

**Independent Test**: Can be tested by creating multiple split expenses and verifying the balance screen shows correct amounts owed between members.

**Acceptance Scenarios**:

1. **Given** there are split expenses in my home, **When** I open the balances screen, **Then** I see net amounts owed between each pair of members
2. **Given** member A paid $60 split equally with member B, **When** I view balances, **Then** member B owes member A $30
3. **Given** multiple expenses exist, **When** I view balances, **Then** the system shows simplified balances (net amounts, not individual transactions)
4. **Given** all debts are settled, **When** I view balances, **Then** I see a "All settled up" state

---

### User Story 5 - Record a Settlement (Priority: P2)

As a home member, I want to record when I pay someone back so that our balance is updated correctly.

**Why this priority**: Settlements complete the expense-sharing cycle and keep balances accurate.

**Independent Test**: Can be tested by recording a settlement between two members and verifying the balance decreases accordingly.

**Acceptance Scenarios**:

1. **Given** I owe another member money, **When** I record a settlement for the full amount, **Then** the balance between us becomes zero
2. **Given** I owe another member money, **When** I record a partial settlement, **Then** the balance decreases by the settlement amount
3. **Given** I record a settlement, **When** I choose the payment method (cash, transfer, etc.), **Then** the method is recorded with the settlement
4. **Given** a settlement is recorded, **When** other members view balances, **Then** they see the updated amounts

---

### User Story 6 - View Expense Summary and Reports (Priority: P3)

As a home member, I want to see spending summaries by category and over time so that I can understand our household spending patterns.

**Why this priority**: Summaries provide insights beyond raw expense data but are not essential for core expense tracking.

**Independent Test**: Can be tested by viewing the summary screen with existing expenses and verifying category breakdowns and totals display correctly.

**Acceptance Scenarios**:

1. **Given** my home has expenses, **When** I view the expense summary, **Then** I see total spending for the current month
2. **Given** I am viewing the summary, **When** I select a different time period, **Then** the summary updates to show expenses for that period
3. **Given** I am viewing the summary, **When** I look at the category breakdown, **Then** I see spending per category as amounts and percentages
4. **Given** I am viewing the summary, **When** I look at member contributions, **Then** I see how much each member has paid

---

### Edge Cases

- What happens when a member leaves a home with unsettled balances? → Departure is blocked until all balances are settled; system shows unsettled amounts to the departing member
- How does the system handle expenses recorded in a foreign currency when the home base currency changes?
- What happens when an expense is deleted after settlements have been recorded? → Expense is soft-deleted (marked "cancelled"), settlement records preserved, balances unaffected
- How does the system handle rounding when splitting amounts that don't divide evenly?
- What happens when all members are removed from a split except one? → Treated as personal expense, no split recorded
- What happens when two members edit the same expense simultaneously? → Last-write-wins, no conflict detection

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow members to record expenses with amount, description, date, and category
- **FR-002**: System MUST allow expenses to be split equally among selected members
- **FR-003**: System MUST allow expenses to be split with custom amounts per member
- **FR-004**: System MUST calculate and display net balances between all member pairs
- **FR-005**: System MUST allow members to record settlements (partial or full)
- **FR-006**: System MUST display expense history with filtering by date range, category, and member
- **FR-007**: System MUST display expense summaries by category and time period
- **FR-008**: System MUST support multiple currencies for expenses — members can record in any currency but must manually enter the converted amount in the home's base currency
- **FR-009**: System MUST track who recorded each expense
- **FR-010**: System MUST allow linking expenses to shopping list items
- **FR-011**: System MUST handle rounding correctly when splitting amounts (to the smallest currency unit)
- **FR-012**: System MUST simplify balances to show net amounts (not individual transaction chains)
- **FR-013**: System MUST persist all expense and settlement records
- **FR-014**: System MUST enforce that only home members can view or record expenses for that home
- **FR-015**: System MUST support real-time updates when expenses or settlements are recorded
- **FR-016**: System MUST allow members to edit expenses (amount, description, date, category, splits) with splits recalculated automatically
- **FR-017**: System MUST allow members to soft-delete expenses (mark as "cancelled") while retaining the record for audit purposes
- **FR-018**: System MUST preserve settlement records when an associated expense is soft-deleted
- **FR-019**: System MUST prevent a member from leaving a home if they have unsettled balances with other members
- **FR-020**: System MUST display unsettled balance amounts when a member attempts to leave a home

### Key Entities

- **Expense**: Represents a purchase made for the household. Key attributes: amount, description, date, category, paid by, linked shopping list item, status (active/cancelled)
- **Expense Split**: Represents a member's share of an expense. Key attributes: expense reference, member, amount owed
- **Settlement**: Represents a payment between members. Key attributes: from member, to member, amount, date, payment method
- **Balance**: Calculated view of net amounts owed between members. Derived from expenses and settlements via real-time calculation (not cached).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can record an expense in under 30 seconds
- **SC-002**: Users can view their home's expense history with less than 2 seconds load time
- **SC-003**: Balance calculations are accurate to the smallest currency unit (no rounding errors in totals)
- **SC-004**: 90% of users successfully record and split their first expense without needing help
- **SC-005**: Expense summaries update within 1 second when filters are changed
- **SC-006**: All expense and settlement data persists correctly across app restarts
- **SC-007**: Real-time updates appear for other members within 2 seconds of an expense being recorded

## Assumptions

- The home's member system (from SPEC 02) is already functional and stable
- Category system (from SPEC 04) is available for expense categorization
- The app supports Arabic RTL as per project requirements
- Multi-currency support uses manual conversion (members enter converted amount in home's base currency)
- Expense recording is manual (no receipt scanning or OCR in this phase)
- No payment processing integration (settlements are recorded manually)
- Offline support is deferred (expenses require connectivity for real-time sync)
