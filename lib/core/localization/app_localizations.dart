import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/app_settings_provider.dart';

import 'translations/ar.dart';
import 'translations/en.dart';
import 'translations/tr.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': arTranslations,
    'en': enTranslations,
    'tr': trTranslations,
  };

  String translate(String key, {Map<String, String>? arguments, String? fallback}) {
    final langCode = locale.languageCode;
    String value = _localizedValues[langCode]?[key] ??
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
  String translate(String key, {Map<String, String>? arguments, String? fallback}) {
    final container = ProviderScope.containerOf(this, listen: false);
    return container.read(appLocalizationsProvider).translate(key, arguments: arguments, fallback: fallback);
  }
}
