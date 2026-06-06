import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';

class OnboardingLanguageStep extends StatelessWidget {
  final String selectedLang;
  final String Function(String key) translate;
  final ValueChanged<String> onSelected;

  const OnboardingLanguageStep({
    super.key,
    required this.selectedLang,
    required this.translate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languages = [
      {
        'code': 'ar',
        'name': translate('lang_ar'),
        'flag': '🇸🇦',
        'subtitle': translate('lang_ar_desc'),
      },
      {
        'code': 'en',
        'name': translate('lang_en'),
        'flag': '🇬🇧',
        'subtitle': translate('lang_en_desc'),
      },
      {
        'code': 'tr',
        'name': translate('lang_tr'),
        'flag': '🇹🇷',
        'subtitle': translate('lang_tr_desc'),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('choose_lang'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translate('choose_lang_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          for (final lang in languages)
            _LanguageChoiceCard(
              language: lang,
              isSelected: selectedLang == lang['code'],
              onTap: () => onSelected(lang['code']!),
            ),
        ],
      ),
    );
  }
}

class _LanguageChoiceCard extends StatelessWidget {
  final Map<String, String> language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChoiceCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedScale(
        scale: isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: SawaCard(
          hasBorder: isSelected,
          backgroundColor: isSelected
              ? theme.primaryColor.withValues(alpha: 0.12)
              : null,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Text(language['flag']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language['name']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.primaryColor : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        language['subtitle']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.primaryColor,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
