import 'dart:ui' as ui;
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:flutter/material.dart';

class AppSettingsRepository {
  static const _themeModeKey = 'settings.theme_mode';
  static const _localeKey = 'settings.locale';
  static const _fontSizeScaleKey = 'settings.font_size_scale';
  static const _hapticFeedbackKey = 'settings.haptic_feedback';
  static const _soundEffectsKey = 'settings.sound_effects';
  static const _keepScreenOnKey = 'settings.keep_screen_on';
  static const _compactListModeKey = 'settings.compact_list_mode';
  static const _groupedByCategoryKey = 'settings.grouped_by_category';
  static const _syncOverWifiOnlyKey = 'settings.sync_over_wifi_only';
  static const _countryKey = 'settings.country';
  static const _dialectKey = 'settings.dialect';

  Future<ThemeMode> getThemeMode() async {
    final prefs = AppPreferences.instance;
    final value = prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = AppPreferences.instance;
    await prefs.setString(_themeModeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<Locale> getLocale() async {
    final prefs = AppPreferences.instance;
    final value = prefs.getString(_localeKey);
    if (value != null) {
      return switch (value) {
        'en' => const Locale('en', 'US'),
        'tr' => const Locale('tr', 'TR'),
        _ => const Locale('ar', 'SA'),
      };
    }

    // Default to device locale if not set
    try {
      final deviceLanguageCode = ui.PlatformDispatcher.instance.locale.languageCode;
      return switch (deviceLanguageCode) {
        'ar' => const Locale('ar', 'SA'),
        'tr' => const Locale('tr', 'TR'),
        _ => const Locale('en', 'US'), // If device language is not supported, default to English
      };
    } catch (_) {
      return const Locale('en', 'US');
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = AppPreferences.instance;
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<double> getFontSizeScale() async {
    final prefs = AppPreferences.instance;
    return prefs.getDouble(_fontSizeScaleKey) ?? 1.0;
  }

  Future<void> setFontSizeScale(double scale) async {
    final prefs = AppPreferences.instance;
    await prefs.setDouble(_fontSizeScaleKey, scale);
  }

  Future<bool> getHapticFeedback() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_hapticFeedbackKey) ?? true;
  }

  Future<void> setHapticFeedback(bool enabled) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_hapticFeedbackKey, enabled);
  }

  Future<bool> getSoundEffects() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_soundEffectsKey) ?? true;
  }

  Future<void> setSoundEffects(bool enabled) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_soundEffectsKey, enabled);
  }

  Future<bool> getKeepScreenOn() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_keepScreenOnKey) ?? false;
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_keepScreenOnKey, enabled);
  }

  Future<bool> getCompactListMode() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_compactListModeKey) ?? false;
  }

  Future<void> setCompactListMode(bool enabled) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_compactListModeKey, enabled);
  }

  Future<bool> getGroupedByCategory() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_groupedByCategoryKey) ?? true;
  }

  Future<void> setGroupedByCategory(bool enabled) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_groupedByCategoryKey, enabled);
  }

  Future<bool> getSyncOverWifiOnly() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_syncOverWifiOnlyKey) ?? false;
  }

  Future<void> setSyncOverWifiOnly(bool enabled) async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_syncOverWifiOnlyKey, enabled);
  }

  Future<String?> getCountry() async {
    final prefs = AppPreferences.instance;
    return prefs.getString(_countryKey);
  }

  Future<void> setCountry(String? country) async {
    final prefs = AppPreferences.instance;
    if (country == null) {
      await prefs.remove(_countryKey);
    } else {
      await prefs.setString(_countryKey, country);
    }
  }

  Future<String?> getDialect() async {
    final prefs = AppPreferences.instance;
    return prefs.getString(_dialectKey);
  }

  Future<void> setDialect(String? dialect) async {
    final prefs = AppPreferences.instance;
    if (dialect == null) {
      await prefs.remove(_dialectKey);
    } else {
      await prefs.setString(_dialectKey, dialect);
    }
  }
}
