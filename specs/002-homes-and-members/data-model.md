# Data Model: Homes and Members

**Date**: 2026-05-12  
**Feature**: Homes and Members  
**Status**: Complete

## Entities

### Home

Represents a shared workspace for household management.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUID | Yes | auto-generated | Primary key |
| name | TEXT | Yes | - | Home name (user-provided) |
| type | TEXT | Yes | - | Home type (family, couple, etc.) |
| owner_id | UUID | Yes | - | Foreign key to users.id |
| default_currency | TEXT | No | 'TRY' | Default currency code |
| created_at | TIMESTAMP | Yes | NOW() | Creation timestamp |
| updated_at | TIMESTAMP | No | - | Last update timestamp |
| deleted_at | TIMESTAMP | No | - | Soft delete timestamp |

**Constraints**:
- `type` must be one of: family, couple, shared_house, student_housing, single_user, office
- `owner_id` must reference a valid user
- `name` must not be empty

**Relationships**:
- `owner_id` → `users.id` (many-to-one)
- `home_members` → `homes.id` (one-to-many)

### HomeMember

Represents a user's membership in a home.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUID | Yes | auto-generated | Primary key |
| home_id | UUID | Yes | - | Foreign key to homes.id |
| user_id | UUID | Yes | - | Foreign key to users.id |
| role | TEXT | Yes | - | Member role |
| status | TEXT | Yes | 'active' | Membership status |
| joined_at | TIMESTAMP | Yes | NOW() | Join timestamp |
| deleted_at | TIMESTAMP | No | - | Soft delete timestamp |

**Constraints**:
- `role` must be one of: owner, admin, member, viewer
- `status` must be one of: active, inactive, pending
- Unique constraint on (home_id, user_id) where deleted_at IS NULL

**Relationships**:
- `home_id` → `homes.id` (many-to-one)
- `user_id` → `users.id` (many-to-one)

## State Transitions

### Home Lifecycle
```
[Created] → [Active] → [Soft Deleted]
```

### HomeMember Lifecycle
```
[Pending] → [Active] → [Inactive] → [Soft Deleted]
[Active] → [Soft Deleted]
```

## Indexes

```sql
-- Home lookups by owner
CREATE INDEX idx_homes_owner_id ON homes(owner_id) WHERE deleted_at IS NULL;

-- Home member lookups
CREATE INDEX idx_home_members_home_id ON home_members(home_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_home_members_user_id ON home_members(user_id) WHERE deleted_at IS NULL;

-- Unique active membership
CREATE UNIQUE INDEX idx_home_members_unique_active 
ON home_members(home_id, user_id) 
WHERE deleted_at IS NULL;
```

## RLS Policies

### Homes Table

```sql
-- View: Users can see homes they are members of
CREATE POLICY "homes_select" ON homes FOR SELECT
USING (
  deleted_at IS NULL AND (
    id IN (
      SELECT home_id FROM home_members 
      WHERE user_id = auth.uid() 
      AND status = 'active' 
      AND deleted_at IS NULL
    )
  )
);

-- Insert: Authenticated users can create homes
CREATE POLICY "homes_insert" ON homes FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- Update: Owners and admins can update homes
CREATE POLICY "homes_update" ON homes FOR UPDATE
USING (
  id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid() 
    AND role IN ('owner', 'admin') 
    AND status = 'active' 
    AND deleted_at IS NULL
  )
);
```

### HomeMembers Table

```sql
-- View: Users can see members of their homes
CREATE POLICY "home_members_select" ON home_members FOR SELECT
USING (
  deleted_at IS NULL AND (
    home_id IN (
      SELECT home_id FROM home_members 
      WHERE user_id = auth.uid() 
      AND status = 'active' 
      AND deleted_at IS NULL
    )
  )
);

-- Insert: Owners/admins can add members
CREATE POLICY "home_members_insert" ON home_members FOR INSERT
WITH CHECK (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid() 
    AND role IN ('owner', 'admin') 
    AND status = 'active' 
    AND deleted_at IS NULL
  )
);

-- Update: Owners/admins can update members
CREATE POLICY "home_members_update" ON home_members FOR UPDATE
USING (
  home_id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid() 
    AND role IN ('owner', 'admin') 
    AND status = 'active' 
    AND deleted_at IS NULL
  )
);
```

## Database Triggers

```sql
-- Auto-add owner as home member on home creation
CREATE OR REPLACE FUNCTION handle_new_home()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO home_members (home_id, user_id, role, status)
  VALUES (NEW.id, NEW.owner_id, 'owner', 'active');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_home_created
  AFTER INSERT ON homes
  FOR EACH ROW EXECUTE FUNCTION handle_new_home();
```

## Validation Rules

1. **Home Name**: Not empty, max 100 characters
2. **Home Type**: Must be valid enum value
3. **Default Currency**: 3-letter ISO code, defaults to 'TRY'
4. **Member Role**: Must be valid enum value
5. **Member Status**: Must be valid enum value

## Notes

- All timestamps are in UTC
- Soft delete uses `deleted_at` field (null = active)
- Owner cannot delete account until ownership transferred (enforced at app level)
- Subscription limits (max homes, max members) are out of scope for this spec
