# Quickstart: Homes and Members

**Date**: 2026-05-12  
**Feature**: Homes and Members

## Prerequisites

- Flutter SDK installed
- Supabase project configured
- `.env` file with Supabase credentials
- Auth feature implemented (SPEC 01)

## Setup Steps

### 1. Run Database Migrations

The homes and home_members tables should already exist from initial setup. Verify with:

```bash
supabase db diff
```

### 2. Create Feature Structure

```bash
mkdir -p lib/features/homes/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}
```

### 3. Implement Data Layer

1. Create `HomeModel` in `lib/features/homes/data/models/home_model.dart`
2. Create `HomeMemberModel` in `lib/features/homes/data/models/home_member_model.dart`
3. Create `HomeRepository` in `lib/features/homes/data/repositories/home_repository.dart`

### 4. Implement Domain Layer

1. Create `Home` entity in `lib/features/homes/domain/entities/home.dart`
2. Create `HomeMember` entity in `lib/features/homes/domain/entities/home_member.dart`
3. Create use cases in `lib/features/homes/domain/usecases/`

### 5. Implement Presentation Layer

1. Create `HomesNotifier` provider in `lib/features/homes/presentation/providers/homes_provider.dart`
2. Create screens:
   - `HomesListScreen` - Main homes list
   - `CreateHomeScreen` - Create new home form
   - `HomeMembersScreen` - View home members
   - `OnboardingScreen` - First-time user setup

### 6. Update Router

Add routes to `lib/app/router/app_router.dart`:

```dart
GoRoute(
  path: '/homes',
  builder: (context, state) => const HomesListScreen(),
),
GoRoute(
  path: '/homes/create',
  builder: (context, state) => const CreateHomeScreen(),
),
GoRoute(
  path: '/homes/:id/members',
  builder: (context, state) => HomeMembersScreen(
    homeId: state.pathParameters['id']!,
  ),
),
GoRoute(
  path: '/onboarding',
  builder: (context, state) => const OnboardingScreen(),
),
```

### 7. Update Route Guard

Update the router redirect to check for homes:

```dart
redirect: (context, state) {
  final isAuthenticated = SupabaseService.isAuthenticated;
  final isOnAuthRoute = state.matchedLocation.startsWith('/login');
  final isOnOnboarding = state.matchedLocation == '/onboarding';
  
  if (!isAuthenticated && !isOnAuthRoute) return '/login';
  if (isAuthenticated && !hasHomes && !isOnOnboarding) return '/onboarding';
  return null;
},
```

## Verification

1. **Run tests**: `flutter test`
2. **Run analyzer**: `flutter analyze`
3. **Manual testing**:
   - Register new user → should redirect to onboarding
   - Create home → should become owner
   - View homes list → should show created home
   - Switch active home → should update context
   - View members → should show owner

## Known Issues

- Subscription limits not implemented (future spec)
- Ownership transfer not implemented (future spec)
- Realtime sync for homes (SPEC 07)
