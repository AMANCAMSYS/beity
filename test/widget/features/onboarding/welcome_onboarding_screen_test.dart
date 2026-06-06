import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sawa/features/onboarding/presentation/screens/welcome_onboarding_screen.dart';
import 'package:sawa/features/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:sawa/features/onboarding/presentation/widgets/onboarding_dot_indicator.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';

void main() {
  group('WelcomeOnboardingScreen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences.init();
    });

    testWidgets('should display first slide initially', (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      expect(find.byType(OnboardingSlide), findsWidgets);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('should display dot indicator', (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      expect(find.byType(OnboardingDotIndicator), findsOneWidget);
    });

    testWidgets('should display next button', (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      expect(
        find.text(localizations.translate('onboarding_next')),
        findsOneWidget,
      );
    });

    testWidgets('should display skip button', (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      expect(
        find.text(localizations.translate('onboarding_skip')),
        findsOneWidget,
      );
    });

    testWidgets('should navigate to next slide when next button is tapped', (
      tester,
    ) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      // Tap next button
      await tester.tap(find.text(localizations.translate('onboarding_next')));
      await tester.pump(const Duration(milliseconds: 500));

      // Should still have the next button (not on last slide yet)
      expect(
        find.text(localizations.translate('onboarding_next')),
        findsOneWidget,
      );
    });

    testWidgets('should display get started button on last slide', (
      tester,
    ) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      // Navigate to last slide (4 more taps since we start at slide 0 and there are 5 slides)
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text(localizations.translate('onboarding_next')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Now should show get started button
      expect(
        find.text(localizations.translate('onboarding_get_started')),
        findsOneWidget,
      );
    });

    testWidgets('should display slide title', (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      // First slide title should be visible
      expect(
        find.text(localizations.translate('onboarding_slide_1_title')),
        findsOneWidget,
      );
    });

    testWidgets('should display slide subtitle', (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      // First slide subtitle should be visible
      expect(
        find.text(localizations.translate('onboarding_slide_1_subtitle')),
        findsOneWidget,
      );
    });

    testWidgets('should update dot indicator when navigating', (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      );

      await tester.pump();

      // Get initial dot indicator
      final dotIndicator = tester.widget<OnboardingDotIndicator>(
        find.byType(OnboardingDotIndicator),
      );
      expect(dotIndicator.currentIndex, 0);

      // Navigate to next slide
      await tester.tap(find.text(localizations.translate('onboarding_next')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Dot indicator should update
      final updatedDotIndicator = tester.widget<OnboardingDotIndicator>(
        find.byType(OnboardingDotIndicator),
      );
      expect(updatedDotIndicator.currentIndex, 1);
    });
  });
}
