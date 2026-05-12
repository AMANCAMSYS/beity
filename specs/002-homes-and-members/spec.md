# Feature Specification: Homes and Members

**Feature Branch**: `spec-02-homes-and-members`  
**Created**: 2026-05-12  
**Status**: Draft  
**Input**: User description: "Implement homes and membership for Beity. A user can create a home workspace, automatically become its owner, see all homes they belong to, switch the active home, and view active members. Homes represent families, couples, shared houses, student housing, single users, or offices. Only authenticated users can access homes."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a New Home (Priority: P1)

A logged-in user wants to create a new home workspace. They enter a name for the home and select a type (family, couple, shared house, student housing, single user, or office). After creation, they automatically become the owner of that home.

**Why this priority**: Creating a home is the foundation for all shared features. Without a home, users cannot use shopping lists or invite members.

**Independent Test**: Can be fully tested by entering a home name, selecting type, and verifying the home is created with the user as owner.

**Acceptance Scenarios**:

1. **Given** a logged-in user on the create home screen, **When** they enter a valid name and select a type, **Then** the home is created and they are added as owner
2. **Given** a user creates a home, **When** the home is created, **Then** the user is automatically added to home_members with role "owner" and status "active"
3. **Given** a user tries to create a home with an empty name, **When** they submit, **Then** a validation error appears in Arabic

---

### User Story 2 - View My Homes (Priority: P1)

A logged-in user wants to see all homes they belong to. They see a list of homes with their names, types, and member counts. The currently active home is highlighted.

**Why this priority**: Users need to see their homes to know which one they're working in and to switch between them.

**Independent Test**: Can be fully tested by creating multiple homes and verifying all appear in the homes list.

**Acceptance Scenarios**:

1. **Given** a user belongs to multiple homes, **When** they open the homes screen, **Then** all their homes are displayed with name, type, and member count
2. **Given** a user has an active home, **When** they view the homes list, **Then** the active home is visually highlighted
3. **Given** a user has no homes, **When** they open the homes screen, **Then** an empty state appears explaining how to create a home

---

### User Story 3 - Switch Active Home (Priority: P1)

A logged-in user wants to switch their active home. They tap on a different home in the list. The app updates the active home context, and all subsequent operations (shopping lists, etc.) are scoped to the new home.

**Why this priority**: Switching homes is essential for users who belong to multiple households (e.g., their own family and a shared office).

**Independent Test**: Can be fully tested by switching homes and verifying the active home indicator changes.

**Acceptance Scenarios**:

1. **Given** a user viewing the homes list, **When** they tap on a different home, **Then** that home becomes the active home
2. **Given** a user switches active home, **When** they navigate to shopping lists, **Then** only lists from the new active home are shown
3. **Given** a user switches active home, **When** they return to homes list, **Then** the new active home is highlighted

---

### User Story 4 - Mandatory Home Setup After Registration (Priority: P1)

A newly registered user is forced to create or join a home immediately after their first login. They see an onboarding screen explaining the concept of homes and must either create a new home or join an existing one via invitation.

**Why this priority**: This ensures every user has a home context from the beginning, enabling all shared features.

**Independent Test**: Can be fully tested by registering a new account and verifying the user is redirected to home setup screen.

**Acceptance Scenarios**:

1. **Given** a newly registered user logs in for the first time, **When** they reach the home screen, **Then** they are redirected to the home setup screen
2. **Given** a user on the home setup screen, **When** they choose to create a home, **Then** they can create a home and proceed to the app
3. **Given** a user on the home setup screen, **When** they choose to join a home, **Then** they can enter an invitation code and join
4. **Given** a user tries to skip the home setup, **When** they attempt to navigate away, **Then** they are prevented from proceeding without a home

---

### User Story 5 - View Home Members (Priority: P2)

A logged-in user wants to see who is in their current home. They navigate to the members screen and see a list of members with their names, roles, and status.

**Why this priority**: Viewing members helps users understand who has access to the home's data.

**Independent Test**: Can be fully tested by viewing members list for a home with multiple members.

**Acceptance Scenarios**:

1. **Given** a user is in a home with multiple members, **When** they open the members screen, **Then** all active members are listed with name, role, and join date
2. **Given** a user views members, **When** a member has role "owner", **Then** the owner role is clearly indicated
3. **Given** a user views members for a single-user home, **When** they open the screen, **Then** only they appear as the owner

---

### Edge Cases

- What happens when a user tries to create a home with a duplicate name? The system MUST allow it (home names don't need to be unique)
- What happens when the home owner tries to delete their account? The system MUST prevent deletion and require manual ownership transfer first
- What happens when a user is removed from a home while they have it active? The system MUST switch them to another home or prompt selection
- What happens when the network is lost during home creation? The system MUST show an error and allow retry

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated users to create a new home with name and type
- **FR-002**: System MUST automatically add the creator as owner when a home is created
- **FR-003**: System MUST display all homes a user belongs to
- **FR-004**: System MUST show home name, type, and member count in the homes list
- **FR-005**: System MUST allow users to switch their active home
- **FR-006**: System MUST persist the active home selection
- **FR-007**: System MUST scope all data operations to the active home
- **FR-008**: System MUST display all active members of a home
- **FR-009**: System MUST show member roles (owner, admin, member, viewer)
- **FR-010**: System MUST enforce that only authenticated users can access home features
- **FR-011**: System MUST support home types: family, couple, shared house, student housing, single user, office
- **FR-012**: System MUST display empty states in Arabic with clear instructions
- **FR-013**: System MUST use soft deletion for homes (deleted_at timestamp)
- **FR-014**: System MUST prevent users from accessing homes they are not members of
- **FR-015**: System MUST force users to create or join a home immediately after first login
- **FR-016**: System MUST set default currency to TRY (Turkish Lira) if not specified by user
- **FR-017**: System MUST prevent home owner from deleting their account until ownership is transferred
- **FR-018**: System MUST support subscription-based limits for maximum homes per user (to be defined)
- **FR-019**: System MUST support subscription-based limits for maximum members per home (to be defined)

### Key Entities

- **Home**: Represents a shared workspace. Key attributes: unique identifier, name, type, owner (user), default currency, creation timestamp, soft delete timestamp
- **Home Member**: Represents a user's membership in a home. Key attributes: unique identifier, home reference, user reference, role (owner/admin/member/viewer), status (active/inactive/pending), join date, soft delete timestamp

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new home in under 30 seconds
- **SC-002**: Users can switch between homes in under 5 seconds
- **SC-003**: 100% of home creators are automatically added as owner
- **SC-004**: Users can view all members of a home within 2 seconds
- **SC-005**: Empty states are understood by Arabic-speaking users without confusion
- **SC-006**: Users cannot access data from homes they are not members of (100% enforcement)

## Clarifications

### Session 2026-05-12

- Q: ما الحد الأقصى لعدد المنازل التي يمكن للمستخدم إنشائها أو الانضمام إليها؟ → A: سيتم تحديده لاحقاً حسب نوع الاشتراك
- Q: ما الحد الأقصى لعدد الأعضاء في المنزل الواحد؟ → A: سيتم تحديده لاحقاً حسب نوع الاشتراك
- Q: ماذا يحدث عندما يحذف المالك حسابه؟ → A: منع حذف المالك حتى يتم نقل الملكية يدوياً
- Q: هل يجب على المستخدم إنشاء أو الانضمام لمنزل فور تسجيل الدخول؟ → A: إجباري (يجب إنشاء أو الانضمام لمنزل فوراً)
- Q: هل يجب على المستخدم اختيار العملة عند إنشاء المنزل؟ → A: اختياري مع قيمة افتراضية (ليرة تركية TRY)

## Assumptions

- Users can belong to multiple homes simultaneously
- Home names do not need to be unique across the system
- The active home is stored locally and persists across app sessions
- Home types are predefined and cannot be customized by users
- Soft deletion is used for homes to preserve data integrity
- Member status defaults to "active" upon joining
- The owner role cannot be transferred in this spec (ownership transfer is a future feature)
- Home deletion requires removing all members first (out of scope for this spec)
- Maximum homes per user and members per home will be determined by subscription type (out of scope for this spec)
- Default currency is TRY (Turkish Lira) unless user specifies otherwise
- Users must create or join a home immediately after first login (onboarding flow)
