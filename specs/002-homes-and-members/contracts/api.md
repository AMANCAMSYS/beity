# Contracts: Homes and Members

**Date**: 2026-05-12  
**Feature**: Homes and Members

## Supabase Table Contracts

### homes Table

**Access**: Authenticated users only  
**RLS**: Users can only see homes they are members of

#### Read Contract

```typescript
interface Home {
  id: string;           // UUID
  name: string;         // 1-100 characters
  type: HomeType;       // enum value
  owner_id: string;     // UUID referencing users.id
  default_currency: string; // 3-letter ISO code, default 'TRY'
  created_at: string;   // ISO timestamp
  updated_at: string | null;
  deleted_at: string | null;
}

type HomeType = 
  | 'family'
  | 'couple'
  | 'shared_house'
  | 'student_housing'
  | 'single_user'
  | 'office';
```

#### Write Contract

```typescript
interface CreateHomeInput {
  name: string;         // required, 1-100 chars
  type: HomeType;       // required
  default_currency?: string; // optional, defaults to 'TRY'
}

interface UpdateHomeInput {
  name?: string;        // optional, 1-100 chars
  default_currency?: string; // optional
}
```

### home_members Table

**Access**: Authenticated users, scoped by home membership  
**RLS**: Users can see members of homes they belong to

#### Read Contract

```typescript
interface HomeMember {
  id: string;           // UUID
  home_id: string;      // UUID referencing homes.id
  user_id: string;      // UUID referencing users.id
  role: MemberRole;
  status: MemberStatus;
  joined_at: string;    // ISO timestamp
  deleted_at: string | null;
}

type MemberRole = 'owner' | 'admin' | 'member' | 'viewer';
type MemberStatus = 'active' | 'inactive' | 'pending';
```

#### Write Contract

```typescript
interface AddMemberInput {
  home_id: string;      // required
  user_id: string;      // required
  role?: MemberRole;    // optional, defaults to 'member'
}

interface UpdateMemberInput {
  role?: MemberRole;    // optional
  status?: MemberStatus; // optional
}
```

## Supabase RPC Contracts

### get_user_homes

Returns all homes for the authenticated user with member count.

```typescript
interface UserHome {
  id: string;
  name: string;
  type: HomeType;
  owner_id: string;
  default_currency: string;
  created_at: string;
  member_count: number;
  is_active: boolean;   // whether this is the current active home
}
```

### is_home_owner

Checks if a user is the owner of a specific home.

```typescript
interface IsHomeOwnerParams {
  home_id: string;
  user_id: string;
}

// Returns: boolean
```

## Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| HOME_NOT_FOUND | Home does not exist or user lacks access | 404 |
| HOME_LIMIT_REACHED | User reached subscription home limit | 403 |
| MEMBER_LIMIT_REACHED | Home reached subscription member limit | 403 |
| INVALID_HOME_TYPE | Home type not in allowed enum | 400 |
| ALREADY_MEMBER | User is already a member of this home | 409 |
| OWNER_CANNOT_LEAVE | Owner cannot leave home (must transfer first) | 403 |

## Validation Rules

### Client-Side Validation

1. Home name: Required, 1-100 characters, no leading/trailing spaces
2. Home type: Must be valid enum value
3. Currency: 3-letter ISO code, defaults to 'TRY'

### Server-Side Validation (RLS)

1. Only authenticated users can create homes
2. Creator automatically becomes owner (trigger)
3. Only owners/admins can add members
4. Users can only view homes they are members of
5. Soft delete only (no hard delete)

## Rate Limiting

- Home creation: 10 per hour per user
- Member addition: 50 per hour per home
- Home list refresh: No limit (cached client-side)

## Notes

- All timestamps are UTC
- All IDs are UUIDs
- Soft delete preserves data for audit
- Subscription limits are placeholder (future spec)
