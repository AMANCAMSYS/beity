# Data Model: Auth and User Profile

**Date**: 2026-05-12  
**Feature**: Auth and User Profile  
**Status**: Complete

## Entities

### User (extends auth.users)

Represents a person using the app. Linked to Supabase auth.users by UUID.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUID | Yes | from auth.users | Primary key, foreign key to auth.users |
| full_name | TEXT | Yes | from metadata | User's display name |
| email | TEXT | Yes | from auth | Email address (unique) |
| phone | TEXT | No | null | Phone number |
| avatar_url | TEXT | No | null | URL to profile image |
| created_at | TIMESTAMP | Yes | NOW() | Account creation timestamp |
| updated_at | TIMESTAMP | No | null | Last profile update |

**Constraints**:
- `id` must reference a valid auth.users record
- `email` must be unique
- `full_name` must not be empty

**Relationships**:
- `id` → `auth.users.id` (one-to-one)
- `home_members` → `users.id` (one-to-many, for SPEC 02)

### User Session (managed by Supabase Auth)

Represents an active authentication session. Managed automatically by Supabase.

| Field | Type | Description |
|-------|------|-------------|
| access_token | JWT | Short-lived access token |
| refresh_token | JWT | Long-lived refresh token |
| expires_at | TIMESTAMP | Token expiry time |
| user_id | UUID | Reference to user |

**Note**: Session management is handled by Supabase Auth automatically. No custom table needed.

## State Transitions

### User Lifecycle
```
[Unregistered] → [Registered] → [Active] → [Logged Out] → [Active]
                                ↓
                           [Deleted] (soft delete, future spec)
```

### Auth State
```
[Unauthenticated] → [Authenticating] → [Authenticated]
                         ↓
                    [Error] → [Unauthenticated]
```

## Indexes

```sql
-- Email lookup (already unique)
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- User ID lookup (already primary key)
-- No additional index needed
```

## RLS Policies

### Users Table

```sql
-- View: Users can see their own profile
CREATE POLICY "users_select_own" ON users FOR SELECT
USING (auth.uid() = id);

-- Update: Users can update their own profile
CREATE POLICY "users_update_own" ON users FOR UPDATE
USING (auth.uid() = id);

-- Insert: Handled by trigger (SECURITY DEFINER)
-- No direct insert policy needed
```

## Database Triggers

```sql
-- Auto-create user profile on auth signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

## Validation Rules

1. **Email**: Valid email format, unique in system
2. **Password**: Minimum 8 characters (enforced by Supabase Auth)
3. **Full Name**: Required, 1-100 characters
4. **Phone**: Optional, valid phone format if provided
5. **Avatar URL**: Valid URL format if provided

## Security Considerations

1. **RLS**: Users can only read/update their own profile
2. **Password**: Never stored in public tables (managed by auth.users)
3. **Email**: Unique constraint prevents duplicates
4. **Session**: Tokens managed by Supabase (secure storage)
5. **Trigger**: SECURITY DEFINER ensures profile creation works

## Notes

- All timestamps are in UTC
- Password is never stored in public.users table
- Email is synced from auth.users to public.users
- Profile creation is automatic via trigger
- Multiple sessions allowed (standard Supabase behavior)
