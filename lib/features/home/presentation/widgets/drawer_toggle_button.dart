import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/features/onboarding/presentation/providers/app_tour_target_registry.dart';

class DrawerToggleButton extends ConsumerWidget {
  final String? tooltip;

  const DrawerToggleButton({super.key, this.tooltip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final l10n = ref.watch(appLocalizationsProvider);
    final resolvedTooltip = tooltip ?? l10n.translate('menu');

    return IconButton(
      key: AppTourTargetRegistry.drawerMenuKey,
      icon: CustomPaint(
        size: const Size(22, 22),
        painter: _SidebarIconPainter(
          color: Theme.of(context).colorScheme.onSurface,
          isRtl: isRtl,
        ),
      ),
      tooltip: resolvedTooltip,
      onPressed: () => Scaffold.of(context).openDrawer(),
    );
  }
}

class _SidebarIconPainter extends CustomPainter {
  final Color color;
  final bool isRtl;

  _SidebarIconPainter({required this.color, required this.isRtl});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const r = 3.0;
    const padding = 1.0;

    // Main rounded rectangle
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(padding, padding, w - padding * 2, h - padding * 2),
      const Radius.circular(r),
    );
    canvas.drawRRect(rect, paint);

    // Vertical divider line (sidebar indicator)
    final lineX = isRtl ? w * 0.67 : w * 0.33;
    const top = padding + 3;
    final bottom = h - padding - 3;
    canvas.drawLine(
      Offset(lineX, top),
      Offset(lineX, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SidebarIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isRtl != isRtl;
  }
}

