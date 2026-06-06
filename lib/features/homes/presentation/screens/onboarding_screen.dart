import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/error_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/monitoring/monitoring_service.dart';

import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../widgets/onboarding_country_step.dart';
import '../widgets/onboarding_home_step.dart';
import '../widgets/onboarding_language_step.dart';
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
        final langDefaults = LanguageSettingsDefaults.getForLanguage(
          _selectedLang,
        );
        _selectedCountryCode = langDefaults.countryCode;
        _selectedDialect = langDefaults.dialect;
        _selectedCurrency = langDefaults.currency;
      });
      _prefillHomeName();
    });
  }

  void _prefillHomeName() {
    final user = ref.read(currentUserProvider).value;
    final userName = user?.fullName ?? '';
    if (userName.isNotEmpty) {
      _homeNameController.text = AppLocalizations(
        Locale(_selectedLang),
      ).translate('home_name_user_prefill', arguments: {'name': userName});
    } else {
      _homeNameController.text = AppLocalizations(
        Locale(_selectedLang),
      ).translate('home_name_default_prefill');
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
      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(
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
        await ref
            .read(homesNotifierProvider.notifier)
            .createHome(
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
        MonitoringService().breadcrumbOnboardingComplete();
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_translate('setup_failed')}: ${ErrorFormatter.format(e, context)}',
            ),
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
    final isRTL = AppLocalizations.isRtlLanguage(_selectedLang);
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
                            color: theme.colorScheme.onSurfaceVariant,
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
                                  : theme.colorScheme.surfaceContainerHighest,
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
                    OnboardingLanguageStep(
                      selectedLang: _selectedLang,
                      translate: _translate,
                      onSelected: (lang) {
                        setState(() {
                          _selectedLang = lang;
                          final langDefaults =
                              LanguageSettingsDefaults.getForLanguage(
                                _selectedLang,
                              );
                          _selectedCountryCode = langDefaults.countryCode;
                          _selectedDialect = langDefaults.dialect;
                          _selectedCurrency = langDefaults.currency;
                          _prefillHomeName();
                        });
                      },
                    ),
                    OnboardingCountryStep(
                      selectedCountryCode: _selectedCountryCode,
                      translate: _translate,
                      onSelected: (code, dialect, currency) {
                        setState(() {
                          _selectedCountryCode = code;
                          _selectedDialect = dialect;
                          _selectedCurrency = currency;
                        });
                      },
                    ),
                    OnboardingHomeStep(
                      formKey: _formKey,
                      homeNameController: _homeNameController,
                      isCreateMode: _isCreateMode,
                      selectedHomeType: _selectedHomeType,
                      selectedCurrency: _selectedCurrency,
                      isDark: isDark,
                      translate: _translate,
                      onCreateModeChanged: (value) {
                        setState(() => _isCreateMode = value);
                      },
                      onHomeTypeChanged: (value) {
                        setState(() => _selectedHomeType = value);
                      },
                      onCurrencyChanged: (value) {
                        setState(() => _selectedCurrency = value);
                      },
                    ),
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
                                  ref
                                      .read(appSettingsProvider.notifier)
                                      .setLocale(Locale(_selectedLang));
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
}

class LanguageSettingsDefaults {
  final String countryCode;
  final String dialect;
  final String currency;

  const LanguageSettingsDefaults({
    required this.countryCode,
    required this.dialect,
    required this.currency,
  });

  static const defaults = {
    'tr': LanguageSettingsDefaults(
      countryCode: 'TR',
      dialect: 'turkish',
      currency: 'TRY',
    ),
    'en': LanguageSettingsDefaults(
      countryCode: 'US',
      dialect: 'standard',
      currency: 'USD',
    ),
    'ar': LanguageSettingsDefaults(
      countryCode: 'SA',
      dialect: 'gulf',
      currency: 'SAR',
    ),
  };

  static LanguageSettingsDefaults getForLanguage(String lang) {
    return defaults[lang] ?? defaults['ar']!;
  }
}
