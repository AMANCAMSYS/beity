# Quickstart: Auth and User Profile

**Date**: 2026-05-12  
**Feature**: Auth and User Profile

## Prerequisites

- Flutter SDK installed
- Supabase project configured
- `.env` file with Supabase credentials
- Database trigger created (see data-model.md)

## Setup Steps

### 1. Verify Database Setup

Ensure the users table and trigger exist:

```sql
-- Check if users table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'users'
);

-- Check if trigger exists
SELECT EXISTS (
  SELECT FROM information_schema.triggers 
  WHERE trigger_name = 'on_auth_user_created'
);
```

### 2. Create Feature Structure

```bash
mkdir -p lib/features/auth/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens}}
```

### 3. Implement Data Layer

1. Create `UserModel` in `lib/features/auth/data/models/user_model.dart`
2. Create `AuthRepository` in `lib/features/auth/data/repositories/auth_repository.dart`

### 4. Implement Domain Layer

1. Create `User` entity in `lib/features/auth/domain/entities/user.dart`
2. Create use cases:
   - `SignInUseCase` in `lib/features/auth/domain/usecases/sign_in_usecase.dart`
   - `SignUpUseCase` in `lib/features/auth/domain/usecases/sign_up_usecase.dart`
   - `SignOutUseCase` in `lib/features/auth/domain/usecases/sign_out_usecase.dart`
   - `UpdateProfileUseCase` in `lib/features/auth/domain/usecases/update_profile_usecase.dart`

### 5. Implement Presentation Layer

1. Create providers:
   - `AuthProvider` in `lib/features/auth/presentation/providers/auth_provider.dart`
2. Create screens:
   - `LoginScreen` in `lib/features/auth/presentation/screens/login_screen.dart`
   - `RegisterScreen` in `lib/features/auth/presentation/screens/register_screen.dart`
   - `ProfileScreen` in `lib/features/auth/presentation/screens/profile_screen.dart`

### 6. Update Router

Add routes to `lib/app/router/app_router.dart`:

```dart
GoRoute(
  path: '/login',
  builder: (context, state) => const LoginScreen(),
),
GoRoute(
  path: '/register',
  builder: (context, state) => const RegisterScreen(),
),
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
),
```

### 7. Implement Auth Guard

Update the router redirect:

```dart
redirect: (context, state) {
  final isAuthenticated = SupabaseService.isAuthenticated;
  final isOnAuthRoute = state.matchedLocation.startsWith('/login') ||
                       state.matchedLocation.startsWith('/register');
  
  if (!isAuthenticated && !isOnAuthRoute) return '/login';
  if (isAuthenticated && isOnAuthRoute) return '/';
  return null;
},
```

## Verification

1. **Run tests**: `flutter test`
2. **Run analyzer**: `flutter analyze`
3. **Manual testing**:
   - Register new user → should create account and redirect to home
   - Login with credentials → should authenticate and redirect
   - View profile → should display user info
   - Edit profile → should save changes
   - Logout → should end session and redirect to login
   - Try accessing protected route without auth → should redirect to login

## Known Issues

- Password reset not implemented (future spec)
- Email verification optional for MVP
- Social login not in scope
- Avatar upload not in scope (URL only)
