import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/app_settings_provider.dart';

import 'translations/ar.dart';
import 'translations/en.dart';
import 'translations/tr.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLanguages = {'ar', 'en', 'tr'};
  static const _rtlLanguages = {'ar', 'fa', 'he', 'ur'};

  static bool isRtlLanguage(String lang) => _rtlLanguages.contains(lang);

  bool get isRtl => isRtlLanguage(locale.languageCode);
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': arTranslations,
    'en': enTranslations,
    'tr': trTranslations,
  };

  String translate(
    String key, {
    Map<String, String>? arguments,
    String? fallback,
  }) {
    final langCode = locale.languageCode;
    String value =
        _localizedValues[langCode]?[key] ??
        _localizedValues['ar']?[key] ??
        fallback ??
        key;

    if (arguments != null) {
      arguments.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }

    return value;
  }
}

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return AppLocalizations(settings.locale);
});

extension LocalizationExtension on BuildContext {
  String translate(
    String key, {
    Map<String, String>? arguments,
    String? fallback,
  }) {
    final container = ProviderScope.containerOf(this, listen: false);
    return container
        .read(appLocalizationsProvider)
        .translate(key, arguments: arguments, fallback: fallback);
  }

  bool get isRtl {
    final container = ProviderScope.containerOf(this, listen: false);
    return container.read(appLocalizationsProvider).isRtl;
  }

  TextDirection get textDirection {
    final container = ProviderScope.containerOf(this, listen: false);
    return container.read(appLocalizationsProvider).textDirection;
  }
}
