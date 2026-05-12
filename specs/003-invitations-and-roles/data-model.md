# Data Model: Invitations and Roles

**Date**: 2026-05-12  
**Feature**: SPEC 03 - Invitations and Roles

## Entities

### 1. Invitation

Represents an invitation to join a home.

**Table**: `invitations`

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | uuid | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| home_id | uuid | FOREIGN KEY (homes.id), NOT NULL | Reference to home |
| inviter_id | uuid | FOREIGN KEY (auth.users.id), NOT NULL | User who sent invitation |
| invitee_email | text | NOT NULL | Email of invited user |
| role | text | NOT NULL, CHECK (role IN ('admin', 'member', 'viewer')) | Role to assign on acceptance |
| status | text | NOT NULL, DEFAULT 'pending', CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled', 'expired')) | Invitation status |
| expires_at | timestamptz | NOT NULL | Expiration timestamp |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update timestamp |

**Constraints**:
- UNIQUE (home_id, invitee_email) WHERE status = 'pending'
- CHECK (expires_at > created_at)

**Relationships**:
- `home_id` → `homes.id`
- `inviter_id` → `auth.users.id`

### 2. Home Member

Represents a user's membership in a home.

**Table**: `home_members`

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | uuid | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| home_id | uuid | FOREIGN KEY (homes.id), NOT NULL | Reference to home |
| user_id | uuid | FOREIGN KEY (auth.users.id), NOT NULL | Reference to user |
| role | text | NOT NULL, CHECK (role IN ('owner', 'admin', 'member', 'viewer')) | Member role |
| joined_at | timestamptz | DEFAULT now() | When user joined |
| updated_at | timestamptz | DEFAULT now() | Last update timestamp |

**Constraints**:
- UNIQUE (home_id, user_id)
- One owner per home: UNIQUE (home_id) WHERE role = 'owner'

**Relationships**:
- `home_id` → `homes.id`
- `user_id` → `auth.users.id`

### 3. Role Permission

Defines what each role can do.

**Table**: `role_permissions`

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | uuid | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| role | text | NOT NULL, CHECK (role IN ('owner', 'admin', 'member', 'viewer')) | Role name |
| permission | text | NOT NULL | Permission identifier |
| allowed | boolean | NOT NULL, DEFAULT false | Whether permission is allowed |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |

**Constraints**:
- UNIQUE (role, permission)

**Default Permissions**:

| Role | Can Invite | Can Manage Lists | Can Edit Items | Can View | Can Manage Members | Can Remove Members | Can Transfer Ownership |
|------|------------|------------------|----------------|----------|-------------------|-------------------|----------------------|
| owner | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (except admins) | ❌ |
| member | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| viewer | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |

### 4. Activity Log

Logs invitation and role activities.

**Table**: `activity_logs` (existing)

| Field | Type | Description |
|-------|------|-------------|
| id | uuid | Primary key |
| home_id | uuid | Reference to home |
| user_id | uuid | User who performed action |
| action | text | Action type |
| entity_type | text | Entity type (invitation, member) |
| entity_id | uuid | Entity ID |
| details | jsonb | Additional details |
| created_at | timestamptz | Timestamp |

**New Activity Types**:
- `invitation_sent`
- `invitation_accepted`
- `invitation_declined`
- `invitation_cancelled`
- `invitation_expired`
- `role_changed`
- `member_removed`
- `ownership_transferred`

## State Transitions

### Invitation Status

```
pending → accepted
pending → declined
pending → cancelled
pending → expired (auto)
```

### Role Hierarchy

```
owner > admin > member > viewer
```

- Owner can change any role
- Admin can change member/viewer roles
- No one can demote owner

## RLS Policies

### invitations

```sql
-- Users can view invitations for homes they own/admin
CREATE POLICY "view_home_invitations" ON invitations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = invitations.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );

-- Users can view their own invitations
CREATE POLICY "view_own_invitations" ON invitations
  FOR SELECT USING (
    invitee_email = (SELECT email FROM auth.users WHERE id = auth.uid())
  );

-- Owners/admins can create invitations
CREATE POLICY "create_invitation" ON invitations
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = invitations.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
  );

-- Users can update their own invitations (accept/decline)
CREATE POLICY "update_own_invitation" ON invitations
  FOR UPDATE USING (
    invitee_email = (SELECT email FROM auth.users WHERE id = auth.uid())
    AND status = 'pending'
  );

-- Owners/admins can cancel invitations
CREATE POLICY "cancel_invitation" ON invitations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM home_members
      WHERE home_members.home_id = invitations.home_id
      AND home_members.user_id = auth.uid()
      AND home_members.role IN ('owner', 'admin')
    )
    AND status = 'pending'
  );
```

### home_members

```sql
-- Users can view members of homes they belong to
CREATE POLICY "view_home_members" ON home_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM home_members AS hm
      WHERE hm.home_id = home_members.home_id
      AND hm.user_id = auth.uid()
    )
  );

-- System can add members (via invitation acceptance)
CREATE POLICY "add_member" ON home_members
  FOR INSERT WITH CHECK (true); -- Controlled by function

-- Owners can update member roles
CREATE POLICY "update_member_role" ON home_members
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM home_members AS hm
      WHERE hm.home_id = home_members.home_id
      AND hm.user_id = auth.uid()
      AND hm.role = 'owner'
    )
  );

-- Owners/admins can remove members
CREATE POLICY "remove_member" ON home_members
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM home_members AS hm
      WHERE hm.home_id = home_members.home_id
      AND hm.user_id = auth.uid()
      AND hm.role IN ('owner', 'admin')
    )
  );
```

## Indexes

```sql
-- Invitations
CREATE INDEX idx_invitations_home_id ON invitations(home_id);
CREATE INDEX idx_invitations_invitee_email ON invitations(invitee_email);
CREATE INDEX idx_invitations_status ON invitations(status);
CREATE INDEX idx_invitations_expires_at ON invitations(expires_at);

-- Home Members
CREATE INDEX idx_home_members_home_id ON home_members(home_id);
CREATE INDEX idx_home_members_user_id ON home_members(user_id);
CREATE INDEX idx_home_members_role ON home_members(role);
```
