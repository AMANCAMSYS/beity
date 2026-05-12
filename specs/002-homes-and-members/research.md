# Research: Homes and Members

**Date**: 2026-05-12  
**Feature**: Homes and Members  
**Status**: Complete

## Research Tasks

### 1. Riverpod State Management Pattern

**Decision**: Use `@riverpod` annotations with code generation  
**Rationale**: 
- Type-safe providers with compile-time checks
- Auto-dispose for memory management
- Easy testing with provider overrides

**Alternatives considered**:
- Manual StateNotifier: More boilerplate, less type safety
- Bloc: Overkill for this feature size
- GetX: Not aligned with project's Riverpod choice

**Implementation**:
```dart
@riverpod
class HomesNotifier extends _$HomesNotifier {
  @override
  Future<List<Home>> build() async {
    final repo = ref.read(homeRepositoryProvider);
    return repo.getHomes();
  }
  
  Future<void> createHome(CreateHomeParams params) async {
    // implementation
  }
}
```

### 2. Supabase RLS Policy Pattern for Homes

**Decision**: Use home_members junction table for RLS  
**Rationale**: 
- Existing database schema supports this
- Consistent with spec requirement "users can only access homes they are members of"
- Supports role-based access (owner, admin, member, viewer)

**Pattern**:
```sql
-- Users can view homes they are members of
CREATE POLICY "view_own_homes" ON homes FOR SELECT
USING (
  id IN (
    SELECT home_id FROM home_members 
    WHERE user_id = auth.uid() 
    AND status = 'active' 
    AND deleted_at IS NULL
  )
);
```

### 3. Active Home Persistence Strategy

**Decision**: Use SharedPreferences for local persistence  
**Rationale**: 
- Lightweight key-value storage
- Already in dependencies
- Persists across app sessions
- No need for database query on every app launch

**Pattern**:
```dart
class HomeLocalDataSource {
  static const _activeHomeKey = 'active_home_id';
  
  Future<void> setActiveHome(String homeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeHomeKey, homeId);
  }
  
  Future<String?> getActiveHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeHomeKey);
  }
}
```

### 4. Onboarding Flow for New Users

**Decision**: GoRouter redirect with first-login check  
**Rationale**: 
- Declarative routing with GoRouter
- Can check if user has homes on route change
- Prevents navigation until home is created/joined

**Pattern**:
```dart
GoRouter(
  redirect: (context, state) {
    final isAuthenticated = SupabaseService.isAuthenticated;
    final isOnAuthRoute = state.matchedLocation.startsWith('/login');
    final isOnOnboarding = state.matchedLocation == '/onboarding';
    
    if (!isAuthenticated && !isOnAuthRoute) return '/login';
    if (isAuthenticated && !hasHomes && !isOnOnboarding) return '/onboarding';
    return null;
  },
);
```

### 5. Home Type Enum Strategy

**Decision**: Store as TEXT in database, use enum in Dart  
**Rationale**: 
- Database flexibility (TEXT allows future types without migration)
- Type safety in Dart code
- Supports Arabic display names

**Implementation**:
```dart
enum HomeType {
  family('family', 'عائلة'),
  couple('couple', 'زوجان'),
  sharedHouse('shared_house', 'سكن مشترك'),
  studentHousing('student_housing', 'سكن طلاب'),
  singleUser('single_user', 'مستخدم فردي'),
  office('office', 'مكتب');
  
  final String value;
  final String arabicName;
  
  const HomeType(this.value, this.arabicName);
}
```

### 6. Member Count Query Strategy

**Decision**: Use Supabase RPC for efficient member count  
**Rationale**: 
- Avoids N+1 queries
- Single query for home list with counts
- Can be cached

**Pattern**:
```dart
// Option A: Computed in Dart
final homes = await supabase.from('homes').select('*, home_members(count)');

// Option B: Database function
// CREATE FUNCTION get_home_member_count(home_id UUID)
// Returns integer count of active members
```

## Unresolved Questions

None - all research tasks resolved.

## Next Steps

Proceed to Phase 1: data-model.md and contracts
