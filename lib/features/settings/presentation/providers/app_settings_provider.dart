import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/app_settings_repository.dart';

const Object _unset = Object();

class AppSettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final double fontSizeScale;
  final bool hapticFeedback;
  final bool soundEffects;
  final bool keepScreenOn;
  final bool compactListMode;
  final bool groupedByCategory;
  final bool syncOverWifiOnly;
  final bool purchaseNotifications;
  final String? country;
  final String? dialect;
  final bool isLoading;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar', 'SA'),
    this.fontSizeScale = 1.0,
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.keepScreenOn = false,
    this.compactListMode = false,
    this.groupedByCategory = true,
    this.syncOverWifiOnly = false,
    this.purchaseNotifications = true,
    this.country,
    this.dialect,
    this.isLoading = true,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    double? fontSizeScale,
    bool? hapticFeedback,
    bool? soundEffects,
    bool? keepScreenOn,
    bool? compactListMode,
    bool? groupedByCategory,
    bool? syncOverWifiOnly,
    bool? purchaseNotifications,
    Object? country = _unset,
    Object? dialect = _unset,
    bool? isLoading,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      compactListMode: compactListMode ?? this.compactListMode,
      groupedByCategory: groupedByCategory ?? this.groupedByCategory,
      syncOverWifiOnly: syncOverWifiOnly ?? this.syncOverWifiOnly,
      purchaseNotifications:
          purchaseNotifications ?? this.purchaseNotifications,
      country: country == _unset ? this.country : country as String?,
      dialect: dialect == _unset ? this.dialect : dialect as String?,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository();
});

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(() {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    _load();
    return const AppSettingsState();
  }

  Future<void> _load() async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final themeMode = await repository.getThemeMode();
    final locale = await repository.getLocale();
    final fontSizeScale = await repository.getFontSizeScale();
    final hapticFeedback = await repository.getHapticFeedback();
    final soundEffects = await repository.getSoundEffects();
    final keepScreenOn = await repository.getKeepScreenOn();
    final compactListMode = await repository.getCompactListMode();
    final groupedByCategory = await repository.getGroupedByCategory();
    final syncOverWifiOnly = await repository.getSyncOverWifiOnly();
    final purchaseNotifications = await repository.getPurchaseNotifications();
    final country = await repository.getCountry();
    final dialect = await repository.getDialect();

    state = state.copyWith(
      themeMode: themeMode,
      locale: locale,
      fontSizeScale: fontSizeScale,
      hapticFeedback: hapticFeedback,
      soundEffects: soundEffects,
      keepScreenOn: keepScreenOn,
      compactListMode: compactListMode,
      groupedByCategory: groupedByCategory,
      syncOverWifiOnly: syncOverWifiOnly,
      purchaseNotifications: purchaseNotifications,
      country: country,
      dialect: dialect,
      isLoading: false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(themeMode: mode);
      await repository.setThemeMode(mode);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setLocale(Locale locale) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(locale: locale);
      await repository.setLocale(locale);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setFontSizeScale(double scale) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(fontSizeScale: scale);
      await repository.setFontSizeScale(scale);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setHapticFeedback(bool enabled) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(hapticFeedback: enabled);
      await repository.setHapticFeedback(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setSoundEffects(bool enabled) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(soundEffects: enabled);
      await repository.setSoundEffects(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(keepScreenOn: enabled);
      await repository.setKeepScreenOn(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setCompactListMode(bool enabled) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(compactListMode: enabled);
      await repository.setCompactListMode(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setGroupedByCategory(bool enabled) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(groupedByCategory: enabled);
      await repository.setGroupedByCategory(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setSyncOverWifiOnly(bool enabled) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(syncOverWifiOnly: enabled);
      await repository.setSyncOverWifiOnly(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setPurchaseNotifications(bool enabled) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(purchaseNotifications: enabled);
      await repository.setPurchaseNotifications(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setCountry(String? country) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(country: country);
      await repository.setCountry(country);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setDialect(String? dialect) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    final oldState = state;
    try {
      state = state.copyWith(dialect: dialect);
      await repository.setDialect(dialect);
    } catch (_) {
      state = oldState;
    }
  }
}
