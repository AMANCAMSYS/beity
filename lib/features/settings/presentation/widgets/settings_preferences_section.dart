import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import 'font_size_bottom_sheet.dart';
import 'country_dialect_bottom_sheet.dart';
import 'settings_shared_widgets.dart';

class SettingsPreferencesSection extends ConsumerWidget {
  final AppSettingsState settings;
  final AppLocalizations l10n;

  const SettingsPreferencesSection({
    super.key,
    required this.settings,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSizeLabel = switch (settings.fontSizeScale) {
      <= 0.85 => l10n.translate('small'),
      <= 1.0 => l10n.translate('normal'),
      <= 1.15 => l10n.translate('large'),
      _ => l10n.translate('huge'),
    };

    final isArabic = settings.locale.languageCode == 'ar';
    final isTurkish = settings.locale.languageCode == 'tr';

    // Map country code to readable string
    final countryLabel = switch (settings.country) {
      'SA' => isArabic ? 'المملكة العربية السعودية (لهجة خليجية)' : (isTurkish ? 'Suudi Arabistan (Körfez Ağzı)' : 'Saudi Arabia (Gulf Dialect)'),
      'EG' => isArabic ? 'جمهورية مصر العربية (لهجة مصرية)' : (isTurkish ? 'Mısır (Mısır Ağzı)' : 'Egypt (Egyptian Dialect)'),
      'TR' => isArabic ? 'الجمهورية التركية (لهجة تركية)' : (isTurkish ? 'Türkiye (Türkçe Terimler)' : 'Turkey (Turkish Dialect)'),
      'AE' => isArabic ? 'الإمارات العربية المتحدة (لهجة خليجية)' : (isTurkish ? 'Birleşik Arap Emirlikleri (Körfez Ağzı)' : 'United Arab Emirates (Gulf Dialect)'),
      'JO' => isArabic ? 'الأردن وبلاد الشام (لهجة شامية)' : (isTurkish ? 'Ürdün ve Levant (Levant Ağzı)' : 'Jordan & Levant (Levantine Dialect)'),
      _ => isArabic ? 'دولة أخرى / عالمي (عربية فصحى)' : (isTurkish ? 'Diğer / Küresel (Arapça / Türkçe)' : 'Other / Global (Standard Arabic / English)'),
    };

    return SettingsSection(
      title: l10n.translate('app_preferences'),
      children: [
        ThemeModeTile(settings: settings, l10n: l10n),
        const SettingsDivider(),
        LanguageTile(settings: settings),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.public_rounded,
          title: isArabic ? 'بلد اللهجة والذكاء الاصطناعي' : (isTurkish ? 'YZ Ülke ve Ağız Ayarı' : 'AI Country & Dialect'),
          subtitle: countryLabel,
          onTap: () => CountryDialectBottomSheet.show(
            context,
            ref,
            currentCountry: settings.country,
            currentDialect: settings.dialect,
            languageCode: settings.locale.languageCode,
          ),
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.format_size_rounded,
          title: l10n.translate('font_size'),
          subtitle: l10n.translate('current_font_size', arguments: {'label': fontSizeLabel}),
          onTap: () => FontSizeBottomSheet.show(
            context,
            ref,
            initialScale: settings.fontSizeScale,
            l10n: l10n,
          ),
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.sync_rounded,
          title: l10n.translate('sync_status'),
          subtitle: l10n.translate('sync_status_subtitle'),
          onTap: () => context.push('/settings/sync-status'),
        ),
      ],
    );
  }
}
