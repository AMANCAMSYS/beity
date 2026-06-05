import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
      purchaseNotifications: purchaseNotifications ?? this.purchaseNotifications,
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
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
      return AppSettingsNotifier(ref.read(appSettingsRepositoryProvider));
    });

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final AppSettingsRepository _repository;

  AppSettingsNotifier(this._repository) : super(const AppSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final themeMode = await _repository.getThemeMode();
    final locale = await _repository.getLocale();
    final fontSizeScale = await _repository.getFontSizeScale();
    final hapticFeedback = await _repository.getHapticFeedback();
    final soundEffects = await _repository.getSoundEffects();
    final keepScreenOn = await _repository.getKeepScreenOn();
    final compactListMode = await _repository.getCompactListMode();
    final groupedByCategory = await _repository.getGroupedByCategory();
    final syncOverWifiOnly = await _repository.getSyncOverWifiOnly();
    final purchaseNotifications = await _repository.getPurchaseNotifications();
    final country = await _repository.getCountry();
    final dialect = await _repository.getDialect();

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
    final oldState = state;
    try {
      state = state.copyWith(themeMode: mode);
      await _repository.setThemeMode(mode);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setLocale(Locale locale) async {
    final oldState = state;
    try {
      state = state.copyWith(locale: locale);
      await _repository.setLocale(locale);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setFontSizeScale(double scale) async {
    final oldState = state;
    try {
      state = state.copyWith(fontSizeScale: scale);
      await _repository.setFontSizeScale(scale);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setHapticFeedback(bool enabled) async {
    final oldState = state;
    try {
      state = state.copyWith(hapticFeedback: enabled);
      await _repository.setHapticFeedback(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setSoundEffects(bool enabled) async {
    final oldState = state;
    try {
      state = state.copyWith(soundEffects: enabled);
      await _repository.setSoundEffects(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    final oldState = state;
    try {
      state = state.copyWith(keepScreenOn: enabled);
      await _repository.setKeepScreenOn(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setCompactListMode(bool enabled) async {
    final oldState = state;
    try {
      state = state.copyWith(compactListMode: enabled);
      await _repository.setCompactListMode(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setGroupedByCategory(bool enabled) async {
    final oldState = state;
    try {
      state = state.copyWith(groupedByCategory: enabled);
      await _repository.setGroupedByCategory(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setSyncOverWifiOnly(bool enabled) async {
    final oldState = state;
    try {
      state = state.copyWith(syncOverWifiOnly: enabled);
      await _repository.setSyncOverWifiOnly(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setPurchaseNotifications(bool enabled) async {
    final oldState = state;
    try {
      state = state.copyWith(purchaseNotifications: enabled);
      await _repository.setPurchaseNotifications(enabled);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setCountry(String? country) async {
    final oldState = state;
    try {
      state = state.copyWith(country: country);
      await _repository.setCountry(country);
    } catch (_) {
      state = oldState;
    }
  }

  Future<void> setDialect(String? dialect) async {
    final oldState = state;
    try {
      state = state.copyWith(dialect: dialect);
      await _repository.setDialect(dialect);
    } catch (_) {
      state = oldState;
    }
  }
}
