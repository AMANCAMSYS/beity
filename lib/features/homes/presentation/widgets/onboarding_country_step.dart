import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';

typedef OnboardingCountrySelected =
    void Function(String code, String dialect, String currency);

class OnboardingCountryStep extends StatelessWidget {
  final String selectedCountryCode;
  final String Function(String key) translate;
  final OnboardingCountrySelected onSelected;

  const OnboardingCountryStep({
    super.key,
    required this.selectedCountryCode,
    required this.translate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countries = [
      {
        'code': 'SA',
        'name': translate('country_sa'),
        'flag': '🇸🇦',
        'dialect': 'gulf',
        'currency': 'SAR',
        'dialectDesc': translate('dialect_gulf'),
        'currencyDesc': translate('currency_sa'),
      },
      {
        'code': 'EG',
        'name': translate('country_eg'),
        'flag': '🇪🇬',
        'dialect': 'egyptian',
        'currency': 'EGP',
        'dialectDesc': translate('dialect_egyptian'),
        'currencyDesc': translate('currency_eg'),
      },
      {
        'code': 'TR',
        'name': translate('country_tr'),
        'flag': '🇹🇷',
        'dialect': 'turkish',
        'currency': 'TRY',
        'dialectDesc': translate('dialect_turkish'),
        'currencyDesc': translate('currency_tr'),
      },
      {
        'code': 'AE',
        'name': translate('country_ae'),
        'flag': '🇦🇪',
        'dialect': 'gulf',
        'currency': 'AED',
        'dialectDesc': translate('dialect_gulf'),
        'currencyDesc': translate('currency_ae'),
      },
      {
        'code': 'JO',
        'name': translate('country_jo'),
        'flag': '🇯🇴',
        'dialect': 'levantine',
        'currency': 'JOD',
        'dialectDesc': translate('dialect_levantine'),
        'currencyDesc': translate('currency_jo'),
      },
      {
        'code': 'US',
        'name': translate('country_other'),
        'flag': '🌐',
        'dialect': 'standard',
        'currency': 'USD',
        'dialectDesc': translate('dialect_standard'),
        'currencyDesc': translate('currency_other'),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('choose_country'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translate('choose_country_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          for (final country in countries)
            _CountryChoiceCard(
              country: country,
              isSelected: selectedCountryCode == country['code'],
              onTap: () => onSelected(
                country['code']!,
                country['dialect']!,
                country['currency']!,
              ),
            ),
        ],
      ),
    );
  }
}

class _CountryChoiceCard extends StatelessWidget {
  final Map<String, String> country;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryChoiceCard({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Text(country['flag']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country['name']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.primaryColor : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        country['dialectDesc']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.primaryColor.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w500 : null,
                        ),
                      ),
                      Text(
                        country['currencyDesc']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
