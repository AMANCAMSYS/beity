import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/features/auth/presentation/screens/login_screen.dart';
import 'package:sawa/features/auth/data/repositories/auth_repository.dart';
import 'package:sawa/features/auth/data/models/user_model.dart';
import 'package:sawa/features/auth/presentation/providers/auth_provider.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/providers/provider_lifecycle_manager.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockProviderLifecycleManager extends Mock
    implements ProviderLifecycleManager {}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

final _testUser = UserModel(
  id: 'user-123',
  fullName: 'Test User',
  email: 'test@example.com',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockProviderLifecycleManager mockLifecycle;
  late MockHomeLocalDataSource mockLocalDs;

  setUpAll(() {
    registerFallbackValue(const Locale('en', 'US'));
  });

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockLifecycle = MockProviderLifecycleManager();
    mockLocalDs = MockHomeLocalDataSource();

    SupabaseService.client = mockSupabaseClient;
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(
      () => mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockGoTrueClient.currentUser).thenReturn(null);
    when(
      () => mockLocalDs.setInitialSyncCompleted(any(), any()),
    ).thenAnswer((_) async {});
  });

  Widget buildLoginScreen({
    AuthRepository? authRepo,
    ProviderLifecycleManager? lifecycleManager,
    HomeLocalDataSource? localDataSource,
  }) {
    final localizations = AppLocalizations(const Locale('en', 'US'));

    return ProviderScope(
      overrides: [
        appLocalizationsProvider.overrideWithValue(localizations),
        authRepositoryProvider.overrideWithValue(authRepo ?? mockAuthRepo),
        providerLifecycleManagerProvider.overrideWithValue(
          lifecycleManager ?? mockLifecycle,
        ),
        homeLocalDataSourceProvider.overrideWithValue(
          localDataSource ?? mockLocalDs,
        ),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen', () {
    // ── Existing UI tests ────────────────────────────────────────────

    testWidgets('should display email input field', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
      expect(
        find.text(
          AppLocalizations(const Locale('en', 'US')).translate('email'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display password input field', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppLocalizations(const Locale('en', 'US')).translate('password'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display login button', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppLocalizations(const Locale('en', 'US')).translate('login'),
        ),
        findsWidgets,
      );
    });

    testWidgets('should display Google sign-in button', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppLocalizations(
            const Locale('en', 'US'),
          ).translate('sign_in_with_google'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display SAWA title', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizations(const Locale('en', 'US')).translate('sawa')),
        findsOneWidget,
      );
    });

    testWidgets('should display create account link', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      final l10n = AppLocalizations(const Locale('en', 'US'));
      expect(find.text(l10n.translate('dont_have_account')), findsOneWidget);
      expect(find.text(l10n.translate('create_account')), findsOneWidget);
    });

    testWidgets('should display OR divider', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizations(const Locale('en', 'US')).translate('or')),
        findsOneWidget,
      );
    });

    testWidgets('should display home icon', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('should display email icon', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.email_rounded), findsOneWidget);
    });

    testWidgets('should display lock icon', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('should display visibility toggle for password', (
      tester,
    ) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });

    testWidgets('should toggle password visibility when icon is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });

    testWidgets('should accept text input in email field', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should accept text input in password field', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('should display Google icon in sign-in button', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    // ── T038: Sign-in success/failure flow tests ────────────────────

    testWidgets('successful sign-in shows loading indicator', (tester) async {
      // Make signIn complete after a delay so we can observe loading state
      final completer = Completer<UserModel>();
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      // Tap the login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login').first);
      await tester.pump();

      // Should show loading state (CircularProgressIndicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the sign-in
      completer.complete(_testUser);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'failed sign-in with invalid credentials shows error snackbar',
      (tester) async {
        when(
          () => mockAuthRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Invalid login credentials'));

        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'bad@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Login').first);
        await tester.pumpAndSettle();

        // Should show a SnackBar with error
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets('failed sign-in with network error shows error snackbar', (
      tester,
    ) async {
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('SocketException: Failed host lookup'));

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login').first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    // ── T039: Google sign-in failure tests ──────────────────────────

    testWidgets('Google sign-in failure shows error snackbar', (tester) async {
      when(
        () => mockAuthRepo.signInWithGoogle(),
      ).thenThrow(const AuthException('google_login_failed'));

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Tap the Google sign-in button
      await tester.tap(find.byIcon(Icons.g_mobiledata));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Google sign-in cancelled shows error snackbar', (
      tester,
    ) async {
      when(
        () => mockAuthRepo.signInWithGoogle(),
      ).thenThrow(const AuthException('google_sign_in_not_supported'));

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.g_mobiledata));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
