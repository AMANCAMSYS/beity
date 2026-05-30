import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../app/theme/app_colors.dart';

/// Slide index → illustration configuration.
class _IllustrationConfig {
  final IconData primary;
  final IconData secondary;
  final IconData tertiary;
  final Color primaryColor;
  final Color secondaryColor;

  const _IllustrationConfig({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

const _configs = [
  _IllustrationConfig(
    primary: Icons.shopping_cart_rounded,
    secondary: Icons.people_rounded,
    tertiary: Icons.auto_awesome_rounded,
    primaryColor: AppColors.primary,
    secondaryColor: AppColors.primaryLight,
  ),
  _IllustrationConfig(
    primary: Icons.shopping_bag_rounded,
    secondary: Icons.touch_app_rounded,
    tertiary: Icons.check_circle_rounded,
    primaryColor: AppColors.secondary,
    secondaryColor: AppColors.secondaryLight,
  ),
  _IllustrationConfig(
    primary: Icons.home_rounded,
    secondary: Icons.inventory_2_rounded,
    tertiary: Icons.account_balance_wallet_rounded,
    primaryColor: AppColors.accent,
    secondaryColor: AppColors.accentLight,
  ),
  _IllustrationConfig(
    primary: Icons.smart_toy_rounded,
    secondary: Icons.restaurant_menu_rounded,
    tertiary: Icons.lightbulb_rounded,
    primaryColor: AppColors.info,
    secondaryColor: AppColors.infoContainer,
  ),
  _IllustrationConfig(
    primary: Icons.receipt_long_rounded,
    secondary: Icons.inventory_2_rounded,
    tertiary: Icons.pie_chart_rounded,
    primaryColor: AppColors.warning,
    secondaryColor: Colors.orange, // A suitable light color for warning
  ),
];

/// Animated icon-composition illustration for each onboarding slide.
class OnboardingIllustration extends StatefulWidget {
  final int slideIndex;

  const OnboardingIllustration({super.key, required this.slideIndex});

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.slideIndex.clamp(0, _configs.length - 1);
    final cfg = _configs[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cfg.primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
              ),
            ),
            // Ring
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cfg.primaryColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            // Primary icon (center)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cfg.primaryColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: cfg.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(cfg.primary, size: 44, color: cfg.primaryColor),
            ),
            // Secondary icon (top-right)
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = math.sin(_controller.value * math.pi * 2) * 4;
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cfg.secondaryColor.withValues(alpha: isDark ? 0.3 : 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: cfg.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(cfg.secondary, size: 24, color: cfg.primaryColor),
                ),
              ),
            ),
            // Tertiary icon (bottom-left)
            Positioned(
              bottom: 10,
              left: 10,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = math.cos(_controller.value * math.pi * 2) * 4;
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cfg.secondaryColor.withValues(alpha: isDark ? 0.3 : 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: cfg.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(cfg.tertiary, size: 20, color: cfg.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
