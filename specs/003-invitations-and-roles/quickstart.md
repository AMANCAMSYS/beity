# Quickstart: Invitations and Roles

**Date**: 2026-05-12  
**Feature**: SPEC 03 - Invitations and Roles

## Overview

This feature implements the invitation and role management system for Beity. Users can invite others to join homes via email, accept/decline invitations, and manage member roles.

## Prerequisites

- Flutter SDK installed
- Supabase project configured
- Firebase project configured (for FCM)
- Existing Beity app running

## Setup Steps

### 1. Database Setup

Run the following SQL in Supabase SQL Editor:

```sql
-- Create invitations table
CREATE TABLE IF NOT EXISTS invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
  inviter_id UUID NOT NULL REFERENCES auth.users(id),
  invitee_email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'member', 'viewer')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled', 'expired')),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (home_id, invitee_email) WHERE status = 'pending'
);

-- Create role_permissions table
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  permission TEXT NOT NULL,
  allowed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (role, permission)
);

-- Enable RLS
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_invitations_home_id ON invitations(home_id);
CREATE INDEX idx_invitations_invitee_email ON invitations(invitee_email);
CREATE INDEX idx_invitations_status ON invitations(status);
CREATE INDEX idx_home_members_role ON home_members(role);

-- Insert default permissions
INSERT INTO role_permissions (role, permission, allowed) VALUES
  ('owner', 'can_invite', true),
  ('owner', 'can_manage_lists', true),
  ('owner', 'can_edit_items', true),
  ('owner', 'can_view', true),
  ('owner', 'can_manage_members', true),
  ('owner', 'can_remove_members', true),
  ('owner', 'can_transfer_ownership', true),
  ('admin', 'can_invite', true),
  ('admin', 'can_manage_lists', true),
  ('admin', 'can_edit_items', true),
  ('admin', 'can_view', true),
  ('admin', 'can_manage_members', true),
  ('admin', 'can_remove_members', true),
  ('admin', 'can_transfer_ownership', false),
  ('member', 'can_invite', false),
  ('member', 'can_manage_lists', false),
  ('member', 'can_edit_items', true),
  ('member', 'can_view', true),
  ('member', 'can_manage_members', false),
  ('member', 'can_remove_members', false),
  ('member', 'can_transfer_ownership', false),
  ('viewer', 'can_invite', false),
  ('viewer', 'can_manage_lists', false),
  ('viewer', 'can_edit_items', false),
  ('viewer', 'can_view', true),
  ('viewer', 'can_manage_members', false),
  ('viewer', 'can_remove_members', false),
  ('viewer', 'can_transfer_ownership', false);
```

### 2. Supabase Functions

Create the following functions in Supabase:

```sql
-- Function to send invitation
CREATE OR REPLACE FUNCTION send_invitation(
  p_home_id UUID,
  p_invitee_email TEXT,
  p_role TEXT
) RETURNS invitations AS $$
DECLARE
  v_invitation invitations;
BEGIN
  -- Check if user is owner/admin
  -- Check if invitee is not already member
  -- Check if no pending invitation exists
  -- Create invitation
  INSERT INTO invitations (home_id, inviter_id, invitee_email, role, expires_at)
  VALUES (p_home_id, auth.uid(), p_invitee_email, p_role, now() + INTERVAL '7 days')
  RETURNING * INTO v_invitation;
  
  -- Log activity
  INSERT INTO activity_logs (home_id, user_id, action, entity_type, entity_id, details)
  VALUES (p_home_id, auth.uid(), 'invitation_sent', 'invitation', v_invitation.id, 
          jsonb_build_object('invitee_email', p_invitee_email, 'role', p_role));
  
  RETURN v_invitation;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept invitation
CREATE OR REPLACE FUNCTION accept_invitation(
  p_invitation_id UUID
) RETURNS home_members AS $$
DECLARE
  v_invitation invitations;
  v_member home_members;
BEGIN
  -- Get invitation
  SELECT * INTO v_invitation FROM invitations WHERE id = p_invitation_id;
  
  -- Validate invitation
  IF v_invitation.status != 'pending' THEN
    RAISE EXCEPTION 'Invitation is not pending';
  END IF;
  
  IF v_invitation.expires_at < now() THEN
    RAISE EXCEPTION 'Invitation has expired';
  END IF;
  
  -- Update invitation status
  UPDATE invitations SET status = 'accepted', updated_at = now() WHERE id = p_invitation_id;
  
  -- Add member
  INSERT INTO home_members (home_id, user_id, role)
  VALUES (v_invitation.home_id, auth.uid(), v_invitation.role)
  RETURNING * INTO v_member;
  
  -- Log activity
  INSERT INTO activity_logs (home_id, user_id, action, entity_type, entity_id, details)
  VALUES (v_invitation.home_id, auth.uid(), 'invitation_accepted', 'invitation', p_invitation_id,
          jsonb_build_object('role', v_invitation.role));
  
  RETURN v_member;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. Flutter Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^14.0.0
```

### 4. Feature Structure

Create the following directory structure:

```
lib/features/invitations/
├── data/
│   ├── models/
│   │   ├── invitation_model.dart
│   │   └── role_permission_model.dart
│   └── repositories/
│       ├── invitation_repository.dart
│       └── role_repository.dart
├── domain/
│   ├── entities/
│   │   ├── invitation.dart
│   │   ├── role.dart
│   │   └── role_permission.dart
│   └── usecases/
│       ├── send_invitation_usecase.dart
│       ├── accept_invitation_usecase.dart
│       ├── decline_invitation_usecase.dart
│       ├── cancel_invitation_usecase.dart
│       ├── change_member_role_usecase.dart
│       ├── remove_member_usecase.dart
│       └── transfer_ownership_usecase.dart
└── presentation/
    ├── providers/
    │   ├── invitations_provider.dart
    │   └── roles_provider.dart
    ├── screens/
    │   ├── invitations_list_screen.dart
    │   ├── send_invitation_screen.dart
    │   └── manage_roles_screen.dart
    └── widgets/
        ├── invitation_card_widget.dart
        └── role_selector_widget.dart
```

## Testing

### Unit Tests

```bash
flutter test test/unit/features/invitations/
```

### Integration Tests

```bash
flutter test test/integration/features/invitations/
```

### Widget Tests

```bash
flutter test test/widget/features/invitations/
```

## Verification

1. **Send Invitation**: Create invitation, verify it appears in list
2. **Accept Invitation**: Accept invitation, verify membership added
3. **Decline Invitation**: Decline invitation, verify status changed
4. **Cancel Invitation**: Cancel invitation, verify status changed
5. **Change Role**: Change member role, verify permissions update
6. **Remove Member**: Remove member, verify access revoked
7. **Transfer Ownership**: Transfer ownership, verify new owner

## Next Steps

After completing this feature:
1. Run `flutter analyze` to check for issues
2. Run `flutter test` to verify all tests pass
3. Proceed to SPEC 04 - Shopping Lists
