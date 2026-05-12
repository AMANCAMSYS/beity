# API Contract: Invitations and Roles

**Date**: 2026-05-12  
**Feature**: SPEC 03 - Invitations and Roles

## Supabase Tables

### invitations

**Operations**:

| Operation | Method | Description |
|-----------|--------|-------------|
| Send Invitation | INSERT | Create new invitation |
| View Invitations | SELECT | List invitations for home or user |
| Accept Invitation | UPDATE | Change status to 'accepted' |
| Decline Invitation | UPDATE | Change status to 'declined' |
| Cancel Invitation | UPDATE | Change status to 'cancelled' |
| Expire Invitation | UPDATE | Change status to 'expired' (cron) |

### home_members

**Operations**:

| Operation | Method | Description |
|-----------|--------|-------------|
| Add Member | INSERT | Add user to home (on accept) |
| View Members | SELECT | List home members |
| Change Role | UPDATE | Update member role |
| Remove Member | DELETE | Remove user from home |

### role_permissions

**Operations**:

| Operation | Method | Description |
|-----------|--------|-------------|
| Get Permissions | SELECT | Get permissions for role |
| Update Permission | UPDATE | Change permission (owner only) |

## Supabase Functions

### send_invitation

**Purpose**: Send invitation with validation  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_invitee_email` (text): Invitee email
- `p_role` (text): Role to assign

**Returns**: invitation record

**Validations**:
- User is owner/admin of home
- Invitee not already member
- No pending invitation exists
- Invitee email is valid

### accept_invitation

**Purpose**: Accept invitation and add member  
**Parameters**:
- `p_invitation_id` (uuid): Invitation ID

**Returns**: home_member record

**Validations**:
- Invitation exists and is pending
- Invitation not expired
- Current user is invitee

### decline_invitation

**Purpose**: Decline invitation  
**Parameters**:
- `p_invitation_id` (uuid): Invitation ID

**Returns**: invitation record

### cancel_invitation

**Purpose**: Cancel pending invitation  
**Parameters**:
- `p_invitation_id` (uuid): Invitation ID

**Returns**: invitation record

**Validations**:
- User is owner/admin of home
- Invitation is pending

### change_member_role

**Purpose**: Change member's role  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_user_id` (uuid): User ID
- `p_new_role` (text): New role

**Returns**: home_member record

**Validations**:
- Current user is owner
- Target is not owner
- New role is valid

### remove_member

**Purpose**: Remove member from home  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_user_id` (uuid): User ID

**Returns**: void

**Validations**:
- Current user is owner/admin
- Target is not owner
- Admin cannot remove admin

### transfer_ownership

**Purpose**: Transfer home ownership  
**Parameters**:
- `p_home_id` (uuid): Home ID
- `p_new_owner_id` (uuid): New owner user ID

**Returns**: void

**Validations**:
- Current user is owner
- New owner is member of home

## Realtime Subscriptions

### invitations

**Channel**: `invitations:home_id={home_id}`  
**Events**: INSERT, UPDATE  
**Use Case**: Live updates when invitation status changes

### home_members

**Channel**: `home_members:home_id={home_id}`  
**Events**: INSERT, UPDATE, DELETE  
**Use Case**: Live updates when members change

## Error Codes

| Code | Description |
|------|-------------|
| INVITATION_ALREADY_EXISTS | Pending invitation already exists |
| ALREADY_MEMBER | User is already a member |
| INVITATION_EXPIRED | Invitation has expired |
| INVITATION_NOT_FOUND | Invitation not found |
| NOT_AUTHORIZED | User not authorized for action |
| CANNOT_REMOVE_OWNER | Cannot remove home owner |
| CANNOT_DEMOTE_OWNER | Cannot demote home owner |
| INVALID_ROLE | Invalid role specified |
