import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/error_formatter.dart';
import '../../../../core/localization/app_localizations.dart';

import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _homeNameController = TextEditingController();

  bool _isCreateMode = true;
  int _currentStep = 0;
  String _selectedLang = 'ar';
  String _selectedCountryCode = 'SA';
  String _selectedDialect = 'gulf';
  String _selectedCurrency = 'SAR';
  String _selectedHomeType = 'family';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Set initial values based on current locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = ref.read(appSettingsProvider).locale;
      setState(() {
        _selectedLang = currentLocale.languageCode;
        if (_selectedLang == 'tr') {
          _selectedCountryCode = 'TR';
          _selectedDialect = 'turkish';
          _selectedCurrency = 'TRY';
        } else if (_selectedLang == 'en') {
          _selectedCountryCode = 'US';
          _selectedDialect = 'standard';
          _selectedCurrency = 'USD';
        } else {
          _selectedCountryCode = 'SA';
          _selectedDialect = 'gulf';
          _selectedCurrency = 'SAR';
        }
      });
      _prefillHomeName();
    });
  }

  void _prefillHomeName() {
    final user = ref.read(currentUserProvider).value;
    final userName = user?.fullName ?? '';
    if (userName.isNotEmpty) {
      _homeNameController.text = AppLocalizations(Locale(_selectedLang)).translate(
        'home_name_user_prefill',
        arguments: {'name': userName},
      );
    } else {
      _homeNameController.text = AppLocalizations(Locale(_selectedLang)).translate(
        'home_name_default_prefill',
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _homeNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isCreateMode && !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Update user profile preferences in database
      await ref.read(authNotifierProvider.notifier).updateProfile(
            country: _selectedCountryCode,
            dialect: _selectedDialect,
            language: _selectedLang,
          );

      // 2. Update local settings in SharedPreferences
      final settingsNotifier = ref.read(appSettingsProvider.notifier);
      await settingsNotifier.setCountry(_selectedCountryCode);
      await settingsNotifier.setDialect(_selectedDialect);
      await settingsNotifier.setLocale(Locale(_selectedLang));

      // 3. Create initial Home (only if in create mode)
      if (_isCreateMode) {
        await ref.read(homesNotifierProvider.notifier).createHome(
              name: _homeNameController.text.trim(),
              type: _selectedHomeType,
              defaultCurrency: _selectedCurrency,
            );
      } else {
        // In Join mode, the user must accept an invitation. 
        // If they just clicked 'Next' without joining, we should probably warn them,
        // but if they actually joined a home, the HomeScreen will detect it.
        // We will just let them proceed to HomeScreen and if they didn't join, it will bounce them back.
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_translate('setup_failed')}: ${ErrorFormatter.format(e, context)}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _translate(String key) {
    return AppLocalizations(Locale(_selectedLang)).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _selectedLang == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Column(
            children: [
              // Step Header & Stepper indicator
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _translate('welcome_title'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        Text(
                          '${_currentStep + 1} / 3',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Animated Step Bar
                    Row(
                      children: List.generate(3, (index) {
                        final isActive = index <= _currentStep;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? theme.primaryColor
                                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentStep = page);
                  },
                  children: [
                    _buildLanguageStep(isDark),
                    _buildCountryStep(isDark),
                    _buildHomeStep(isDark),
                  ],
                ),
              ),

              // Bottom Navigation Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: SawaButton(
                          text: _translate('back'),
                          type: SawaButtonType.outline,
                          onPressed: _isSubmitting ? null : _prevStep,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SawaButton(
                        text: _currentStep == 2
                            ? _translate('start_journey')
                            : _translate('next'),
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (_currentStep == 0) {
                                  // Instantly update locale for user feedback
                                  ref.read(appSettingsProvider.notifier).setLocale(Locale(_selectedLang));
                                  _prefillHomeName();
                                }
                                _nextStep();
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageStep(bool isDark) {
    final theme = Theme.of(context);

    final languages = [
      {'code': 'ar', 'name': _translate('lang_ar'), 'flag': '🇸🇦', 'subtitle': _translate('lang_ar_desc')},
      {'code': 'en', 'name': _translate('lang_en'), 'flag': '🇬🇧', 'subtitle': _translate('lang_en_desc')},
      {'code': 'tr', 'name': _translate('lang_tr'), 'flag': '🇹🇷', 'subtitle': _translate('lang_tr_desc')},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('choose_lang'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _translate('choose_lang_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ...languages.map((lang) {
            final isSelected = _selectedLang == lang['code'];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: AnimatedScale(
                scale: isSelected ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: SawaCard(
                  hasBorder: isSelected,
                  backgroundColor: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : null,
                  onTap: () {
                    setState(() {
                      _selectedLang = lang['code']!;
                      // Sync country and dialect dynamically on language click
                      if (_selectedLang == 'tr') {
                        _selectedCountryCode = 'TR';
                        _selectedDialect = 'turkish';
                        _selectedCurrency = 'TRY';
                      } else if (_selectedLang == 'en') {
                        _selectedCountryCode = 'US';
                        _selectedDialect = 'standard';
                        _selectedCurrency = 'USD';
                      } else {
                        _selectedCountryCode = 'SA';
                        _selectedDialect = 'gulf';
                        _selectedCurrency = 'SAR';
                      }
                      _prefillHomeName();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Text(
                          lang['flag']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang['name']!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? theme.primaryColor : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang['subtitle']!,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
          }),
        ],
      ),
    );
  }

  Widget _buildCountryStep(bool isDark) {
    final theme = Theme.of(context);

    final countries = [
      {
        'code': 'SA',
        'name': _translate('country_sa'),
        'flag': '🇸🇦',
        'dialect': 'gulf',
        'currency': 'SAR',
        'dialectDesc': _translate('dialect_gulf'),
        'currencyDesc': _translate('currency_sa')
      },
      {
        'code': 'EG',
        'name': _translate('country_eg'),
        'flag': '🇪🇬',
        'dialect': 'egyptian',
        'currency': 'EGP',
        'dialectDesc': _translate('dialect_egyptian'),
        'currencyDesc': _translate('currency_eg')
      },
      {
        'code': 'TR',
        'name': _translate('country_tr'),
        'flag': '🇹🇷',
        'dialect': 'turkish',
        'currency': 'TRY',
        'dialectDesc': _translate('dialect_turkish'),
        'currencyDesc': _translate('currency_tr')
      },
      {
        'code': 'AE',
        'name': _translate('country_ae'),
        'flag': '🇦🇪',
        'dialect': 'gulf',
        'currency': 'AED',
        'dialectDesc': _translate('dialect_gulf'),
        'currencyDesc': _translate('currency_ae')
      },
      {
        'code': 'JO',
        'name': _translate('country_jo'),
        'flag': '🇯🇴',
        'dialect': 'levantine',
        'currency': 'JOD',
        'dialectDesc': _translate('dialect_levantine'),
        'currencyDesc': _translate('currency_jo')
      },
      {
        'code': 'US',
        'name': _translate('country_other'),
        'flag': '🌐',
        'dialect': 'standard',
        'currency': 'USD',
        'dialectDesc': _translate('dialect_standard'),
        'currencyDesc': _translate('currency_other')
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('choose_country'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _translate('choose_country_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          ...countries.map((country) {
            final isSelected = _selectedCountryCode == country['code'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: AnimatedScale(
                scale: isSelected ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: SawaCard(
                  hasBorder: isSelected,
                  backgroundColor: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : null,
                  onTap: () {
                    setState(() {
                      _selectedCountryCode = country['code']!;
                      _selectedDialect = country['dialect']!;
                      _selectedCurrency = country['currency']!;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Text(
                          country['flag']!,
                          style: const TextStyle(fontSize: 28),
                        ),
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
                                  color: isSelected ? theme.primaryColor.withValues(alpha: 0.8) : Colors.grey,
                                  fontWeight: isSelected ? FontWeight.w500 : null,
                                ),
                              ),
                              Text(
                                country['currencyDesc']!,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
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
          }),
        ],
      ),
    );
  }

  Widget _buildHomeStep(bool isDark) {
    final theme = Theme.of(context);

    final homeTypes = [
      {'code': 'family', 'name': _translate('family'), 'icon': Icons.people_outline_rounded},
      {'code': 'couple', 'name': _translate('couple'), 'icon': Icons.favorite_border_rounded},
      {'code': 'single_user', 'name': _translate('single'), 'icon': Icons.person_outline_rounded},
      {'code': 'shared_house', 'name': _translate('shared'), 'icon': Icons.business_outlined},
    ];

    final currencies = [
      {'code': 'SAR', 'name': 'SAR - ${_translate("currency_sa")}'},
      {'code': 'EGP', 'name': 'EGP - ${_translate("currency_eg")}'},
      {'code': 'TRY', 'name': 'TRY - ${_translate("currency_tr")}'},
      {'code': 'AED', 'name': 'AED - ${_translate("currency_ae")}'},
      {'code': 'JOD', 'name': 'JOD - ${_translate("currency_jo")}'},
      {'code': 'USD', 'name': 'USD - ${_translate("currency_other")}'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _translate('setup_home'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _translate('setup_home_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Guidance Info Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _translate('why_home_title'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _translate('why_home_desc'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // Mode Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCreateMode = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isCreateMode ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: _isCreateMode
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _translate('create_new_home'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isCreateMode ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCreateMode = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isCreateMode ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: !_isCreateMode
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _translate('join_existing_home'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: !_isCreateMode ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isCreateMode) ...[
              // Home Name Text Field
              SawaTextField(
                controller: _homeNameController,
                labelText: _translate('home_name_label'),
                hintText: _translate('home_name_hint'),
                prefixIcon: Icons.home_filled,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _translate('home_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Home Type Grid Selection
              Text(
                _translate('home_type_label'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: homeTypes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (context, index) {
                  final type = homeTypes[index];
                  final isSelected = _selectedHomeType == type['code'];

                  return AnimatedScale(
                    scale: isSelected ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: SawaCard(
                      hasBorder: isSelected,
                      backgroundColor: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : null,
                      onTap: () {
                        setState(() {
                          _selectedHomeType = type['code'] as String;
                        });
                      },
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isSelected ? theme.primaryColor : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type['name'] as String,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : null,
                                color: isSelected ? theme.primaryColor : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Currency Selector Dropdown
              Text(
                _translate('currency_label'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: currencies.map((curr) {
                      return DropdownMenuItem<String>(
                        value: curr['code'],
                        child: Text(
                          curr['name']!,
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                ),
              ),
            ] else ...[
              // Join Mode Content
              SawaCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mark_email_unread_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _translate('join_home_title'),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _translate('join_home_desc'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: SawaButton(
                          text: _translate('check_invitations'),
                          icon: Icons.list_alt_rounded,
                          onPressed: () {
                            context.push('/invitations');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
