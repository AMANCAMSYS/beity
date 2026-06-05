import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:sawa/features/auth/data/repositories/auth_repository.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    repository = AuthRepositoryImpl(mockClient);
  });

  group('signOut', () {
    test('should call auth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('signUp', () {
    test('treats missing session as email confirmation required', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => AuthResponse(
          user: const User(
            id: 'user-123',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-06-01T00:00:00Z',
            email: 'new@example.com',
          ),
        ),
      );

      expect(
        () => repository.signUp(
          email: 'new@example.com',
          password: 'Password123!',
          fullName: 'New User',
        ),
        throwsA(
          isA<EmailConfirmationRequiredException>()
              .having((error) => error.email, 'email', 'new@example.com')
              .having(
                (error) => error.code,
                'code',
                'email_confirmation_required',
              ),
        ),
      );
    });
  });

  group('getCurrentUser', () {
    test('should return null when no user is logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.getCurrentUser();

      expect(result, isNull);
    });
  });

  group('authStateChanges', () {
    test('should return auth.onAuthStateChange stream', () {
      final controller = StreamController<AuthState>.broadcast();
      when(
        () => mockAuth.onAuthStateChange,
      ).thenAnswer((_) => controller.stream);

      final stream = repository.authStateChanges;

      expect(stream, isA<Stream<AuthState>>());
      controller.close();
    });
  });
}
