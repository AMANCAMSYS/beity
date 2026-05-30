import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:beity/features/settings/data/repositories/app_settings_repository.dart';
import 'package:beity/features/settings/presentation/screens/settings_screen.dart';
import 'package:beity/features/auth/presentation/providers/auth_provider.dart';
import 'package:beity/features/homes/presentation/providers/homes_provider.dart';
import 'package:beity/features/homes/data/models/home_model.dart';
import 'package:beity/core/localization/app_localizations.dart';

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

void main() {
  testWidgets('SettingsScreen should render user summary card and settings sections', (tester) async {
    final localizations = AppLocalizations(const Locale('en', 'US'));
    
    final mockSettingsRepo = MockAppSettingsRepository();
    when(() => mockSettingsRepo.getThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => mockSettingsRepo.getLocale()).thenAnswer((_) async => const Locale('en', 'US'));
    when(() => mockSettingsRepo.getFontSizeScale()).thenAnswer((_) async => 1.0);
    when(() => mockSettingsRepo.getHapticFeedback()).thenAnswer((_) async => true);
    when(() => mockSettingsRepo.getSoundEffects()).thenAnswer((_) async => true);
    when(() => mockSettingsRepo.getKeepScreenOn()).thenAnswer((_) async => true);
    when(() => mockSettingsRepo.getCompactListMode()).thenAnswer((_) async => false);
    when(() => mockSettingsRepo.getGroupedByCategory()).thenAnswer((_) async => true);
    when(() => mockSettingsRepo.getSyncOverWifiOnly()).thenAnswer((_) async => false);
    when(() => mockSettingsRepo.getCountry()).thenAnswer((_) async => 'US');
    when(() => mockSettingsRepo.getDialect()).thenAnswer((_) async => 'standard');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
          appLocalizationsProvider.overrideWithValue(localizations),
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          activeHomeIdProvider.overrideWith((ref) => Stream.value('home-123')),
          userHomesProvider.overrideWith((ref) => Stream.value(<HomeModel>[])),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify critical elements are rendered
    expect(find.text(localizations.translate('settings')), findsOneWidget);
    expect(find.text(localizations.translate('account_area')), findsOneWidget);

    // Drag list to scroll down and reveal off-screen sections
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text(localizations.translate('home_organization')), findsOneWidget);
    expect(find.text(localizations.translate('app_preferences')), findsOneWidget);
  });
}
