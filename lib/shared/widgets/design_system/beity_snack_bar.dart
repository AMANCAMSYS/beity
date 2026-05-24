import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

enum BeitySnackType { success, error, warning, info }

class BeitySnackBar {
  static void show(
    BuildContext context, {
    required String message,
    BeitySnackType type = BeitySnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(_icon(type), color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: _color(type),
      duration: duration,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void success(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: BeitySnackType.success, actionLabel: actionLabel, onAction: onAction);
  }

  static void error(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: BeitySnackType.error, actionLabel: actionLabel, onAction: onAction);
  }

  static void warning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: BeitySnackType.warning, actionLabel: actionLabel, onAction: onAction);
  }

  static void info(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: BeitySnackType.info, actionLabel: actionLabel, onAction: onAction);
  }

  static Color _color(BeitySnackType type) {
    switch (type) {
      case BeitySnackType.success:
        return AppColors.success;
      case BeitySnackType.error:
        return AppColors.error;
      case BeitySnackType.warning:
        return AppColors.warning;
      case BeitySnackType.info:
        return AppColors.info;
    }
  }

  static IconData _icon(BeitySnackType type) {
    switch (type) {
      case BeitySnackType.success:
        return Icons.check_circle_rounded;
      case BeitySnackType.error:
        return Icons.error_rounded;
      case BeitySnackType.warning:
        return Icons.warning_rounded;
      case BeitySnackType.info:
        return Icons.info_rounded;
    }
  }
}
