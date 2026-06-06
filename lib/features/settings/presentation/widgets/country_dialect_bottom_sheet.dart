import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class CountryDialectBottomSheet extends ConsumerStatefulWidget {
  final String? currentCountry;
  final String? currentDialect;
  final String languageCode;

  const CountryDialectBottomSheet({
    super.key,
    required this.currentCountry,
    required this.currentDialect,
    required this.languageCode,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String? currentCountry,
    required String? currentDialect,
    required String languageCode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryDialectBottomSheet(
        currentCountry: currentCountry,
        currentDialect: currentDialect,
        languageCode: languageCode,
      ),
    );
  }

  @override
  ConsumerState<CountryDialectBottomSheet> createState() =>
      _CountryDialectBottomSheetState();
}

class _CountryDialectBottomSheetState
    extends ConsumerState<CountryDialectBottomSheet> {
  String? _selectedCountry;
  String? _selectedDialect;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.currentCountry ?? 'SA';
    _selectedDialect = widget.currentDialect ?? 'gulf';
  }

  String _translate(String key) {
    if (key == 'title') return context.translate('ai_country_dialect');
    if (key == 'subtitle') return context.translate('ai_country_dialect_desc');
    if (key == 'success') {
      return context.translate('ai_country_dialect_success');
    }
    if (key == 'failed') return context.translate('ai_country_dialect_failed');
    return context.translate(key);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      // 1. Update remote profile database
      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(country: _selectedCountry, dialect: _selectedDialect);

      // 2. Update local SharedPreferences
      final notifier = ref.read(appSettingsProvider.notifier);
      await notifier.setCountry(_selectedCountry);
      await notifier.setDialect(_selectedDialect);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translate('success')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_translate('failed')}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRTL = AppLocalizations.isRtlLanguage(widget.languageCode);

    final countries = [
      {
        'code': 'SA',
        'name': _translate('country_sa'),
        'flag': '🇸🇦',
        'dialect': 'gulf',
        'dialectDesc': _translate('dialect_gulf'),
      },
      {
        'code': 'EG',
        'name': _translate('country_eg'),
        'flag': '🇪🇬',
        'dialect': 'egyptian',
        'dialectDesc': _translate('dialect_egyptian'),
      },
      {
        'code': 'TR',
        'name': _translate('country_tr'),
        'flag': '🇹🇷',
        'dialect': 'turkish',
        'dialectDesc': _translate('dialect_turkish'),
      },
      {
        'code': 'AE',
        'name': _translate('country_ae'),
        'flag': '🇦🇪',
        'dialect': 'gulf',
        'dialectDesc': _translate('dialect_gulf'),
      },
      {
        'code': 'JO',
        'name': _translate('country_jo'),
        'flag': '🇯🇴',
        'dialect': 'levantine',
        'dialectDesc': _translate('dialect_levantine'),
      },
      {
        'code': 'US',
        'name': _translate('country_other'),
        'flag': '🌐',
        'dialect': 'standard',
        'dialectDesc': _translate('dialect_standard'),
      },
    ];

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _translate('title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _translate('subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final isSelected = _selectedCountry == country['code'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: AnimatedScale(
                        scale: isSelected ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: SawaCard(
                          backgroundColor: isSelected
                              ? theme.primaryColor.withValues(alpha: 0.12)
                              : null,
                          hasBorder: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedCountry = country['code']!;
                              _selectedDialect = country['dialect']!;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  country['flag']!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country['name']!,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? theme.primaryColor
                                                  : null,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        country['dialectDesc']!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.grey),
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
                  },
                ),
              ),
              const SizedBox(height: 16),
              SawaButton(
                text: _translate('save'),
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
