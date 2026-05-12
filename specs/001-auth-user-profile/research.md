# Research: Auth and User Profile

**Date**: 2026-05-12  
**Feature**: Auth and User Profile  
**Status**: Complete

## Research Tasks

### 1. Supabase Auth Integration Pattern

**Decision**: Use `supabase_flutter` auth methods directly  
**Rationale**: 
- Official Supabase Flutter package
- Handles token management automatically
- Built-in session persistence
- Supports email/password natively

**Alternatives considered**:
- Custom auth with REST API: Unnecessary complexity
- Firebase Auth: Project uses Supabase, not Firebase for auth
- OAuth2 packages: Out of scope for MVP

**Implementation**:
```dart
// Registration
final response = await SupabaseService.client.auth.signUp(
  email: email,
  password: password,
  data: {'full_name': name},
);

// Login
final response = await SupabaseService.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// Logout
await SupabaseService.client.auth.signOut();
```

### 2. User Profile Sync Strategy

**Decision**: Database trigger to auto-create user profile on signup  
**Rationale**: 
- Ensures profile always exists after auth
- Atomic operation (no race conditions)
- Works even if app crashes after auth but before profile creation

**Pattern**:
```sql
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

### 3. GoRouter Auth Guard Pattern

**Decision**: Declarative redirect in GoRouter configuration  
**Rationale**: 
- Single source of truth for auth state
- Declarative (no imperative navigation)
- Works with Riverpod for reactive state

**Pattern**:
```dart
GoRouter(
  redirect: (context, state) {
    final isAuthenticated = SupabaseService.isAuthenticated;
    final isOnAuthRoute = state.matchedLocation.startsWith('/login') ||
                         state.matchedLocation.startsWith('/register');
    
    if (!isAuthenticated && !isOnAuthRoute) return '/login';
    if (isAuthenticated && isOnAuthRoute) return '/';
    return null;
  },
);
```

### 4. Riverpod Auth State Management

**Decision**: Use StreamProvider for auth state changes  
**Rationale**: 
- Reactive to auth state changes (login, logout, token refresh)
- Integrates with Supabase's `onAuthStateChange` stream
- Auto-dispose when not needed

**Pattern**:
```dart
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return SupabaseService.client.auth.onAuthStateChange;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<void> build() async {}
  
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.signIn(email: email, password: password);
    });
  }
}
```

### 5. Arabic Error Message Mapping

**Decision**: Map Supabase error codes to Arabic messages  
**Rationale**: 
- User-friendly error messages
- Consistent Arabic UX
- Easy to maintain

**Pattern**:
```dart
class AuthErrorMessages {
  static String mapError(String code) {
    switch (code) {
      case 'invalid_credentials':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'user_already_registered':
        return 'هذا البريد الإلكتروني مسجل بالفعل';
      case 'weak_password':
        return 'كلمة المرور ضعيفة، يجب أن تكون 8 أحرف على الأقل';
      case 'invalid_email':
        return 'البريد الإلكتروني غير صالح';
      default:
        return 'حدث خطأ، يرجى المحاولة مرة أخرى';
    }
  }
}
```

### 6. Session Persistence Strategy

**Decision**: Use Supabase's built-in session persistence  
**Rationale**: 
- Automatic token refresh
- Secure storage (flutter_secure_storage on mobile, localStorage on web)
- No custom implementation needed

**Configuration**:
```dart
await Supabase.initialize(
  url: EnvConfig.supabaseUrl,
  anonKey: EnvConfig.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
);
```

## Unresolved Questions

None - all research tasks resolved.

## Next Steps

Proceed to Phase 1: data-model.md and contracts
