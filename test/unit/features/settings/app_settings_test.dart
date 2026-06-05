import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';

void main() {
  group('AppSettingsState Unit Tests', () {
    test('Initial AppSettingsState uses correct defaults', () {
      const state = AppSettingsState();

      expect(state.themeMode, ThemeMode.system);
      expect(state.locale.languageCode, 'ar');
      expect(state.locale.countryCode, 'SA');
      expect(state.fontSizeScale, 1.0);
      expect(state.hapticFeedback, isTrue);
      expect(state.soundEffects, isTrue);
      expect(state.keepScreenOn, isFalse);
      expect(state.compactListMode, isFalse);
      expect(state.groupedByCategory, isTrue);
      expect(state.syncOverWifiOnly, isFalse);
      expect(state.isLoading, isTrue);
    });

    test('copyWith correctly updates specified fields', () {
      const original = AppSettingsState();

      final updated = original.copyWith(
        themeMode: ThemeMode.dark,
        locale: const Locale('en', 'US'),
        fontSizeScale: 1.15,
        hapticFeedback: false,
        soundEffects: false,
        keepScreenOn: true,
        compactListMode: true,
        groupedByCategory: false,
        syncOverWifiOnly: true,
        isLoading: false,
      );

      // Verify changed fields
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.locale.languageCode, 'en');
      expect(updated.locale.countryCode, 'US');
      expect(updated.fontSizeScale, 1.15);
      expect(updated.hapticFeedback, isFalse);
      expect(updated.soundEffects, isFalse);
      expect(updated.keepScreenOn, isTrue);
      expect(updated.compactListMode, isTrue);
      expect(updated.groupedByCategory, isFalse);
      expect(updated.syncOverWifiOnly, isTrue);
      expect(updated.isLoading, isFalse);

      // Verify original remains unchanged (immutable check)
      expect(original.themeMode, ThemeMode.system);
      expect(original.hapticFeedback, isTrue);
      expect(original.keepScreenOn, isFalse);
    });

    test('copyWith does not change fields when parameters are null', () {
      const original = AppSettingsState(
        themeMode: ThemeMode.light,
        hapticFeedback: false,
        keepScreenOn: true,
      );

      final updated = original.copyWith();

      expect(updated.themeMode, ThemeMode.light);
      expect(updated.hapticFeedback, isFalse);
      expect(updated.keepScreenOn, isTrue);
    });

    test('copyWith can clear nullable country and dialect fields', () {
      const original = AppSettingsState(country: 'SA', dialect: 'gulf');

      final updated = original.copyWith(country: null, dialect: null);

      expect(updated.country, isNull);
      expect(updated.dialect, isNull);
    });
  });
}
