import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import 'onboarding_illustration.dart';

/// Gradient configuration per slide.
const _gradients = [
  [AppColors.primary, AppColors.primaryLight],
  [AppColors.secondary, AppColors.secondaryLight],
  [AppColors.accent, AppColors.accentLight],
  [AppColors.info, AppColors.infoContainer],
];

/// A single slide in the welcome onboarding screen.
///
/// Handles its own fade + upward-slide entrance animation when [isVisible]
/// switches to true.
class OnboardingSlide extends StatefulWidget {
  final int slideIndex;
  final String title;
  final String subtitle;
  final bool isVisible;

  const OnboardingSlide({
    super.key,
    required this.slideIndex,
    required this.title,
    required this.subtitle,
    required this.isVisible,
  });

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    if (widget.isVisible) _textController.forward();
  }

  @override
  void didUpdateWidget(covariant OnboardingSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _textController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.slideIndex.clamp(0, _gradients.length - 1);
    final colors = _gradients[index];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colors[0].withValues(alpha: 0.55),
                  colors[1].withValues(alpha: 0.25),
                ]
              : [colors[0], colors[1]],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              OnboardingIllustration(slideIndex: widget.slideIndex),
              const SizedBox(height: 48),

              // Animated text
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
