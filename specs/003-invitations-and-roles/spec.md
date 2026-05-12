# Feature Specification: Invitations and Roles

**Feature Branch**: `003-invitations-and-roles`  
**Created**: 2026-05-12  
**Status**: Draft  
**Input**: User description: "SPEC 03 — Invitations and Roles"

## Clarifications

### Session 2026-05-12

- Q: هل الدعوات تتم عبر البريد الإلكتروني فقط أم أيضاً عبر رقم الهاتف؟ → A: البريد الإلكتروني فقط
- Q: ما هي صلاحيات كل دور؟ → A: نموذج مخصص: يمكن تخصيص صلاحيات كل دور بشكل منفصل
- Q: ماذا يحدث عندما تنتهي صلاحية الدعوة؟ → A: إلغاء تلقائي + إشعار للمدعو
- Q: كيف يتم نقل ملكية المنزل؟ → A: نقل مباشر: المالك يختار عضواً جديداً ليصبح مالكاً
- Q: كيف يتم إرسال إشعارات الدعوات؟ → A: إشعار داخل التطبيق + push notification (Firebase FCM)

---

## User Scenarios & Testing

### User Story 1 - Send Invitation to Join Home (Priority: P1)

As a home owner or admin, I want to invite new members to my home by email, so that they can join and collaborate on household management.

**Why this priority**: This is the core functionality that enables home sharing. Without invitations, users cannot add members to their homes.

**Independent Test**: Can be fully tested by sending an invitation and verifying it appears in the invitations list.

**Acceptance Scenarios**:

1. **Given** I am a home owner/admin, **When** I enter an email address and send an invitation, **Then** the invitation is created and stored in the system
2. **Given** I am a home owner/admin, **When** I try to invite someone already in the home, **Then** I see an error message indicating they are already a member
3. **Given** I am a home owner/admin, **When** I try to invite someone with a pending invitation, **Then** I see an error indicating an invitation already exists

---

### User Story 2 - Receive and Accept Invitation (Priority: P1)

As a user, I want to receive invitations to join homes and accept them, so that I can become a member of shared households.

**Why this priority**: This completes the invitation flow and enables users to join homes.

**Independent Test**: Can be tested by receiving an invitation and accepting it, then verifying membership.

**Acceptance Scenarios**:

1. **Given** I have a pending invitation, **When** I view my invitations, **Then** I see the home name, inviter name, and invitation date
2. **Given** I have a pending invitation, **When** I accept it, **Then** I become a member of that home with the specified role
3. **Given** I have a pending invitation, **When** I decline it, **Then** the invitation is marked as declined and I remain unchanged

---

### User Story 3 - View and Manage Invitations (Priority: P2)

As a home owner/admin, I want to view all pending invitations for my home and cancel them if needed, so that I can manage who can join.

**Why this priority**: This provides control over the invitation process and allows cleanup of stale invitations.

**Independent Test**: Can be tested by viewing invitations list and cancelling one.

**Acceptance Scenarios**:

1. **Given** I am a home owner/admin, **When** I view invitations for my home, **Then** I see all pending invitations with their status
2. **Given** I am a home owner/admin, **When** I cancel a pending invitation, **Then** the invitation is marked as cancelled and the invitee can no longer accept it

---

### User Story 4 - Assign and Change Member Roles (Priority: P2)

As a home owner, I want to assign roles to members (admin, member, viewer) and change them as needed, so that I can control permissions within my home.

**Why this priority**: Roles enable proper access control and delegation of responsibilities.

**Independent Test**: Can be tested by changing a member's role and verifying their permissions update accordingly.

**Acceptance Scenarios**:

1. **Given** I am a home owner, **When** I change a member's role to admin, **Then** they gain admin privileges (can invite, manage lists)
2. **Given** I am a home owner, **When** I change a member's role to viewer, **Then** they can only view content without editing capabilities
3. **Given** I am an admin, **When** I try to change the owner's role, **Then** I see an error indicating owners cannot be demoted

---

### User Story 5 - Remove Member from Home (Priority: P3)

As a home owner/admin, I want to remove members from my home, so that I can manage home membership when people leave.

**Why this priority**: This is important for maintaining accurate home membership but is less critical than the invitation flow.

**Independent Test**: Can be tested by removing a member and verifying they no longer have access.

**Acceptance Scenarios**:

1. **Given** I am a home owner, **When** I remove a member, **Then** they lose access to the home and all its content
2. **Given** I am an admin, **When** I try to remove another admin, **Then** I see an error indicating only owners can remove admins
3. **Given** I am a home owner, **When** I try to remove myself, **Then** I see an error indicating owners cannot leave (must transfer ownership first via direct transfer)

---

### Edge Cases

- What happens when an invitation expires (after 7 days)? → Auto-cancel with notification to invitee
- How does the system handle inviting a user who doesn't have an account yet?
- What happens when the invited email doesn't match any registered user?
- How does the system handle concurrent role changes by multiple admins?
- What happens when an owner tries to leave the home without transferring ownership? → Must transfer ownership first (direct transfer)

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow home owners and admins to send invitations via email
- **FR-002**: System MUST prevent duplicate invitations to the same email for the same home
- **FR-003**: System MUST allow users to view their pending invitations
- **FR-004**: System MUST allow users to accept or decline invitations
- **FR-005**: System MUST automatically add users to homes when they accept invitations
- **FR-006**: System MUST allow home owners to assign roles (owner, admin, member, viewer) to members
- **FR-007**: System MUST enforce role-based permissions with customizable permissions for each role (owner, admin, member, viewer)
- **FR-008**: System MUST allow home owners and admins to cancel pending invitations
- **FR-009**: System MUST allow home owners and admins to remove members from homes
- **FR-010**: System MUST prevent owners from being removed or demoted
- **FR-011**: System MUST log all invitation and role change activities
- **FR-012**: System MUST send notifications for new invitations via in-app notifications and push notifications (Firebase FCM)
- **FR-013**: System MUST expire invitations after 7 days if not accepted

### Key Entities

- **Invitation**: Represents an invitation to join a home. Key attributes: home_id, inviter_id, invitee_email, role, status (pending/accepted/declined/cancelled), expires_at
- **HomeMember**: Represents a user's membership in a home. Key attributes: home_id, user_id, role, joined_at
- **Role**: Defines permission levels. Values: owner, admin, member, viewer

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can send an invitation in under 30 seconds
- **SC-002**: Users can accept an invitation and become a member in under 1 minute
- **SC-003**: Home owners can view and manage all invitations within 2 clicks
- **SC-004**: Role changes take effect immediately for all users
- **SC-005**: 95% of invitations are successfully delivered to invitees
- **SC-006**: Zero unauthorized access to homes through invitation system

## Assumptions

- Users must have a registered account to accept invitations
- Invitations are sent via email (SMS invitations are out of scope for v1)
- The invitation system uses the existing Supabase email infrastructure
- Role permissions follow a hierarchical model (owner > admin > member > viewer)
- Invitations expire after 7 days by default
- Activity logging uses the existing activity_logs table
