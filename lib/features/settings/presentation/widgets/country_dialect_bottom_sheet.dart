import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/design_system/beity_button.dart';
import '../../../../shared/widgets/design_system/beity_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';

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
  ConsumerState<CountryDialectBottomSheet> createState() => _CountryDialectBottomSheetState();
}

class _CountryDialectBottomSheetState extends ConsumerState<CountryDialectBottomSheet> {
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
    final Map<String, Map<String, String>> localizedValues = {
      'ar': {
        'title': 'بلد اللهجة والذكاء الاصطناعي',
        'subtitle': 'اختر بلدك لتخصيص مصطلحات ولهجة الذكاء الاصطناعي حسب مطبخك المحلي',
        'save': 'حفظ التغييرات',
        'saving': 'جاري الحفظ...',
        'success': 'تم تحديث بلد اللهجة بنجاح',
        'failed': 'فشل التحديث، حاول مرة أخرى',
        'country_sa': 'المملكة العربية السعودية',
        'country_eg': 'جمهورية مصر العربية',
        'country_tr': 'الجمهورية التركية',
        'country_ae': 'الإمارات العربية المتحدة',
        'country_jo': 'الأردن وبلاد الشام',
        'country_other': 'دولة أخرى / عالمي',
        'dialect_gulf': 'لهجة خليجية ومصطلحات سعودية',
        'dialect_egyptian': 'لهجة مصرية ومصطلحات مصرية',
        'dialect_turkish': 'لهجة ومصطلحات تركية',
        'dialect_levantine': 'لهجة شامية ومصطلحات شامية',
        'dialect_standard': 'عربية فصحى مبسطة وعالمية',
      },
      'en': {
        'title': 'AI Country & Dialect',
        'subtitle': 'Select your country to customize AI terminology and dialect to fit your local kitchen',
        'save': 'Save Changes',
        'saving': 'Saving...',
        'success': 'Country & dialect updated successfully',
        'failed': 'Update failed, please try again',
        'country_sa': 'Saudi Arabia',
        'country_eg': 'Egypt',
        'country_tr': 'Turkey',
        'country_ae': 'United Arab Emirates',
        'country_jo': 'Jordan & Levant',
        'country_other': 'Other / Global',
        'dialect_gulf': 'Gulf/Saudi dialect & local naming',
        'dialect_egyptian': 'Egyptian dialect & kitchen naming',
        'dialect_turkish': 'Turkish dialect & terminology',
        'dialect_levantine': 'Levantine dialect & naming',
        'dialect_standard': 'Standard Modern Arabic / English',
      },
      'tr': {
        'title': 'YZ Ülke ve Ağız Ayarı',
        'subtitle': 'YZ terimlerini ve ağzını yerel mutfağınıza göre özelleştirmek için ülkenizi seçin',
        'save': 'Değişiklikleri Kaydet',
        'saving': 'Kaydediliyor...',
        'success': 'Ülke ve ağız başarıyla güncellendi',
        'failed': 'Güncelleme başarısız oldu, lütfen tekrar deneyin',
        'country_sa': 'Suudi Arabistan',
        'country_eg': 'Mısır',
        'country_tr': 'Türkiye',
        'country_ae': 'Birleşik Arap Emirlikleri',
        'country_jo': 'Ürdün ve Levant',
        'country_other': 'Diğer / Küresel',
        'dialect_gulf': 'Körfez/Suudi ağzı ve yerel adlandırma',
        'dialect_egyptian': 'Mısır ağzı ve mutfak adlandırması',
        'dialect_turkish': 'Türkçe ağız ve terimler',
        'dialect_levantine': 'Levant ağzı ve yerel adlandırma',
        'dialect_standard': 'Standart Modern Arapça / Türkçe',
      }
    };

    final lang = widget.languageCode;
    return localizedValues[lang]?[key] ?? localizedValues['ar']?[key] ?? key;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      // 1. Update remote profile database
      await ref.read(authNotifierProvider.notifier).updateProfile(
            country: _selectedCountry,
            dialect: _selectedDialect,
          );

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
    final isRTL = widget.languageCode == 'ar';

    final countries = [
      {
        'code': 'SA',
        'name': _translate('country_sa'),
        'flag': '🇸🇦',
        'dialect': 'gulf',
        'dialectDesc': _translate('dialect_gulf')
      },
      {
        'code': 'EG',
        'name': _translate('country_eg'),
        'flag': '🇪🇬',
        'dialect': 'egyptian',
        'dialectDesc': _translate('dialect_egyptian')
      },
      {
        'code': 'TR',
        'name': _translate('country_tr'),
        'flag': '🇹🇷',
        'dialect': 'turkish',
        'dialectDesc': _translate('dialect_turkish')
      },
      {
        'code': 'AE',
        'name': _translate('country_ae'),
        'flag': '🇦🇪',
        'dialect': 'gulf',
        'dialectDesc': _translate('dialect_gulf')
      },
      {
        'code': 'JO',
        'name': _translate('country_jo'),
        'flag': '🇯🇴',
        'dialect': 'levantine',
        'dialectDesc': _translate('dialect_levantine')
      },
      {
        'code': 'US',
        'name': _translate('country_other'),
        'flag': '🌐',
        'dialect': 'standard',
        'dialectDesc': _translate('dialect_standard')
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
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                        child: BeityCard(
                          backgroundColor: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : null,
                          hasBorder: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedCountry = country['code']!;
                              _selectedDialect = country['dialect']!;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  country['flag']!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
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
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
              BeityButton(
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
