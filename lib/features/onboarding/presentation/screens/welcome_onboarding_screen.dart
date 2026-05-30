import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/onboarding_storage.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/onboarding_dot_indicator.dart';

/// Full-screen welcome onboarding shown once before authentication.
///
/// On completion / skip: marks welcome onboarding as seen and navigates
/// to the login screen.
class WelcomeOnboardingScreen extends StatefulWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  State<WelcomeOnboardingScreen> createState() =>
      _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  static const int _totalSlides = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await OnboardingStorage.markWelcomeOnboardingSeen();
    if (mounted) context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < _totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translate;
    final isLast = _currentPage == _totalSlides - 1;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final slideData = [
      (
        title: t('onboarding_slide_1_title'),
        subtitle: t('onboarding_slide_1_subtitle'),
      ),
      (
        title: t('onboarding_slide_2_title'),
        subtitle: t('onboarding_slide_2_subtitle'),
      ),
      (
        title: t('onboarding_slide_3_title'),
        subtitle: t('onboarding_slide_3_subtitle'),
      ),
      (
        title: t('onboarding_slide_4_title'),
        subtitle: t('onboarding_slide_4_subtitle'),
      ),
      (
        title: t('onboarding_slide_5_title'),
        subtitle: t('onboarding_slide_5_subtitle'),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // ── PageView ─────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _totalSlides,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              return OnboardingSlide(
                slideIndex: i,
                title: slideData[i].title,
                subtitle: slideData[i].subtitle,
                isVisible: i == _currentPage,
              );
            },
          ),

          // ── Skip button (top trailing) ────────────────────────────────
          SafeArea(
            child: Align(
              alignment:
                  isRtl ? Alignment.topLeft : Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AnimatedOpacity(
                  opacity: isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: isLast ? null : _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: Text(
                      t('onboarding_skip'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom: dots + next button ───────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnboardingDotIndicator(
                      count: _totalSlides,
                      currentIndex: _currentPage,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _nextPage,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        child: Text(
                          isLast
                              ? t('onboarding_get_started')
                              : t('onboarding_next'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
