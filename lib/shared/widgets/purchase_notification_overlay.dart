import 'package:flutter/material.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class PurchaseNotificationOverlay extends StatefulWidget {
  final String itemName;
  final String? purchaserName;
  final bool isPurchased;

  const PurchaseNotificationOverlay({
    super.key,
    required this.itemName,
    this.purchaserName,
    required this.isPurchased,
  });

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String itemName,
    String? purchaserName,
    required bool isPurchased,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => PurchaseNotificationOverlay(
        itemName: itemName,
        purchaserName: purchaserName,
        isPurchased: isPurchased,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      if (_currentEntry == entry) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }

  @override
  State<PurchaseNotificationOverlay> createState() =>
      _PurchaseNotificationOverlayState();
}

class _PurchaseNotificationOverlayState
    extends State<PurchaseNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Construct the message
    String message;
    if (widget.isPurchased) {
      if (widget.purchaserName != null && widget.purchaserName!.isNotEmpty) {
        message = context.translate(
          'notification_purchased_by',
          arguments: {
            'purchaser': widget.purchaserName!,
            'item': widget.itemName,
          },
        );
      } else {
        message = context.translate(
          'notification_purchased',
          arguments: {'item': widget.itemName},
        );
      }
    } else {
      if (widget.purchaserName != null && widget.purchaserName!.isNotEmpty) {
        message = context.translate(
          'notification_unpurchased_by',
          arguments: {
            'purchaser': widget.purchaserName!,
            'item': widget.itemName,
          },
        );
      } else {
        message = context.translate(
          'notification_unpurchased',
          arguments: {'item': widget.itemName},
        );
      }
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(opacity: _fadeAnimation.value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isPurchased
                    ? AppColors.success.withValues(alpha: 0.95)
                    : AppColors.error.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isPurchased
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
