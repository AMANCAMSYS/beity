# Contracts: Auth and User Profile

**Date**: 2026-05-12  
**Feature**: Auth and User Profile

## Supabase Auth Contracts

### Registration

**Endpoint**: `supabase.auth.signUp()`  
**Input**:
```typescript
interface SignUpInput {
  email: string;        // required, valid email format
  password: string;     // required, min 8 characters
  data?: {
    full_name: string;  // required, 1-100 chars
  };
}
```

**Output**:
```typescript
interface SignUpOutput {
  user: User | null;
  session: Session | null;
}
```

**Errors**:
- `user_already_registered`: Email already in use
- `weak_password`: Password too short
- `invalid_email`: Invalid email format

### Login

**Endpoint**: `supabase.auth.signInWithPassword()`  
**Input**:
```typescript
interface SignInInput {
  email: string;     // required
  password: string;  // required
}
```

**Output**:
```typescript
interface SignInOutput {
  user: User;
  session: Session;
}
```

**Errors**:
- `invalid_credentials`: Wrong email or password

### Logout

**Endpoint**: `supabase.auth.signOut()`  
**Input**: None  
**Output**: void  
**Errors**: None (always succeeds)

### Get Current User

**Endpoint**: `supabase.auth.currentUser`  
**Input**: None  
**Output**: `User | null`  
**Errors**: None

## Supabase Table Contracts

### users Table

**Access**: Authenticated users only (own profile)  
**RLS**: Users can only see/update their own profile

#### Read Contract

```typescript
interface User {
  id: string;           // UUID (from auth.users)
  full_name: string;    // 1-100 characters
  email: string;        // valid email, unique
  phone: string | null; // optional
  avatar_url: string | null; // optional, valid URL
  created_at: string;   // ISO timestamp
  updated_at: string | null;
}
```

#### Write Contract

```typescript
interface UpdateUserInput {
  full_name?: string;   // optional, 1-100 chars
  phone?: string;       // optional
  avatar_url?: string;  // optional, valid URL
}
```

## Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| INVALID_CREDENTIALS | Wrong email or password | 401 |
| USER_ALREADY_REGISTERED | Email already in use | 409 |
| WEAK_PASSWORD | Password too short | 400 |
| INVALID_EMAIL | Invalid email format | 400 |
| NETWORK_ERROR | Connection lost | 503 |
| SESSION_EXPIRED | Token expired | 401 |

## Validation Rules

### Client-Side Validation

1. Email: Required, valid format (contains @ and domain)
2. Password: Required, minimum 8 characters
3. Full Name: Required, 1-100 characters, no leading/trailing spaces

### Server-Side Validation (Supabase Auth)

1. Email: Valid format, unique in system
2. Password: Minimum 8 characters (configurable)
3. Full Name: Stored in user metadata

## Rate Limiting

- Registration: 5 per hour per IP
- Login: 10 per minute per IP
- Profile update: 30 per minute per user

## Arabic Error Messages

```dart
const errorMessages = {
  'invalid_credentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
  'user_already_registered': 'هذا البريد الإلكتروني مسجل بالفعل',
  'weak_password': 'كلمة المرور ضعيفة، يجب أن تكون 8 أحرف على الأقل',
  'invalid_email': 'البريد الإلكتروني غير صالح',
  'network_error': 'لا يوجد اتصال بالإنترنت',
  'session_expired': 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
};
```

## Notes

- All timestamps are UTC
- All IDs are UUIDs
- Password never stored in public tables
- Session tokens managed by Supabase (secure storage)
- Multiple simultaneous sessions allowed
