import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/providers/provider_lifecycle_manager.dart';
import 'package:sawa/features/auth/data/repositories/auth_repository.dart';
import 'package:sawa/features/auth/data/models/user_model.dart';
import 'package:sawa/features/auth/presentation/providers/auth_provider.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';

// ── Mocks ──────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockProviderLifecycleManager extends Mock
    implements ProviderLifecycleManager {}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

// ── Fixtures ───────────────────────────────────────────────────────────

final _testUser = UserModel(
  id: 'user-123',
  fullName: 'Test User',
  email: 'test@example.com',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

// ── Helpers ────────────────────────────────────────────────────────────

ProviderContainer createContainer({
  AuthRepository? authRepo,
  ProviderLifecycleManager? lifecycleManager,
  HomeLocalDataSource? localDataSource,
}) {
  final mockAuthRepo = authRepo ?? MockAuthRepository();
  final mockLifecycle = lifecycleManager ?? MockProviderLifecycleManager();
  final mockLocalDs = localDataSource ?? MockHomeLocalDataSource();

  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepo),
      providerLifecycleManagerProvider.overrideWithValue(mockLifecycle),
      homeLocalDataSourceProvider.overrideWithValue(mockLocalDs),
    ],
  );
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockProviderLifecycleManager mockLifecycle;
  late MockHomeLocalDataSource mockLocalDs;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockLifecycle = MockProviderLifecycleManager();
    mockLocalDs = MockHomeLocalDataSource();
    authStateController = StreamController<AuthState>.broadcast();

    SupabaseService.client = mockSupabaseClient;
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(
      () => mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => authStateController.stream);
    when(() => mockGoTrueClient.currentUser).thenReturn(null);
    when(
      () => mockLocalDs.setInitialSyncCompleted(any(), any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    authStateController.close();
  });

  // ── T038: Sign-in success/failure ──────────────────────────────────

  group('AuthNotifier signIn', () {
    test('successful sign-in sets state to user data', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'password123');

      final state = container.read(authNotifierProvider);
      expect(state.value, isNotNull);
      expect(state.value!.id, 'user-123');
      expect(state.value!.email, 'test@example.com');
    });

    test('failed sign-in with invalid credentials rethrows', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      expect(
        () => notifier.signIn(email: 'bad@example.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isTrue);
    });

    test('failed sign-in with network error rethrows', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('SocketException: Failed host lookup'));

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      expect(
        () =>
            notifier.signIn(email: 'test@example.com', password: 'password123'),
        throwsA(isA<AuthException>()),
      );

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isTrue);
    });
  });

  // ── T039: Google sign-in failure ───────────────────────────────────

  group('AuthNotifier signInWithGoogle', () {
    test('Google sign-in failure sets error state and rethrows', () async {
      when(
        () => mockAuthRepo.signInWithGoogle(),
      ).thenThrow(const AuthException('google_login_failed'));

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      expect(() => notifier.signInWithGoogle(), throwsA(isA<AuthException>()));

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isTrue);
    });

    test('Google sign-in cancelled by user rethrows', () async {
      when(
        () => mockAuthRepo.signInWithGoogle(),
      ).thenThrow(const AuthException('google_sign_in_not_supported'));

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      expect(() => notifier.signInWithGoogle(), throwsA(isA<AuthException>()));
    });

    test('successful Google sign-in sets state to user data', () async {
      when(
        () => mockAuthRepo.signInWithGoogle(),
      ).thenAnswer((_) async => _testUser);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      final state = container.read(authNotifierProvider);
      expect(state.value, isNotNull);
      expect(state.value!.id, 'user-123');
    });
  });

  // ── T040: Expired/revoked session ──────────────────────────────────

  group('AuthNotifier session handling', () {
    test('expired session transitions to signed-out state', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'pass');

      expect(container.read(authNotifierProvider).value, isNotNull);

      // Simulate Supabase firing a signedOut event (expired session)
      authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));

      // Allow the listener to fire
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authNotifierProvider);
      expect(state.value, isNull);
    });

    test('revoked session transitions to signed-out state', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'pass');

      expect(container.read(authNotifierProvider).value, isNotNull);

      // Simulate Supabase firing a signedOut event (revoked token)
      authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(authNotifierProvider);
      expect(state.value, isNull);
    });

    test('external sign-out is detected and clears user state', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'pass');

      expect(container.read(authNotifierProvider).value, isNotNull);

      // Simulate external sign-out (another tab, admin revocation, etc.)
      authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));

      await Future<void>.delayed(Duration.zero);

      final state = container.read(authNotifierProvider);
      expect(state.value, isNull);

      // Verify providers were invalidated
      verify(() => mockLifecycle.invalidateOnLogout()).called(1);
    });
  });

  // ── T041: Logout cleanup ───────────────────────────────────────────

  group('AuthNotifier signOut', () {
    test('sign-out transitions state to null', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'pass');
      expect(container.read(authNotifierProvider).value, isNotNull);

      await notifier.signOut();

      final state = container.read(authNotifierProvider);
      expect(state.value, isNull);
    });

    test('sign-out invalidates all providers via lifecycle manager', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'pass');
      await notifier.signOut();

      verify(
        () => mockLifecycle.invalidateOnLogout(),
      ).called(greaterThanOrEqualTo(1));
    });

    test('sign-out calls repository signOut', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'pass');
      await notifier.signOut();

      verify(() => mockAuthRepo.signOut()).called(1);
    });

    test('sign-out always transitions to null even with errors', () async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _testUser);
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      final container = createContainer(
        authRepo: mockAuthRepo,
        lifecycleManager: mockLifecycle,
        localDataSource: mockLocalDs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'pass');
      await notifier.signOut();

      // State should always be null after sign-out
      final state = container.read(authNotifierProvider);
      expect(state.value, isNull);
      expect(state.isLoading, isFalse);
    });
  });
}
