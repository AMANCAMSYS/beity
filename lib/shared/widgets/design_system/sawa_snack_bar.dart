import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

enum SawaSnackType { success, error, warning, info }

class SawaSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SawaSnackType type = SawaSnackType.info,
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

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SawaSnackType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SawaSnackType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SawaSnackType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SawaSnackType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static Color _color(SawaSnackType type) {
    switch (type) {
      case SawaSnackType.success:
        return AppColors.success;
      case SawaSnackType.error:
        return AppColors.error;
      case SawaSnackType.warning:
        return AppColors.warning;
      case SawaSnackType.info:
        return AppColors.info;
    }
  }

  static IconData _icon(SawaSnackType type) {
    switch (type) {
      case SawaSnackType.success:
        return Icons.check_circle_rounded;
      case SawaSnackType.error:
        return Icons.error_rounded;
      case SawaSnackType.warning:
        return Icons.warning_rounded;
      case SawaSnackType.info:
        return Icons.info_rounded;
    }
  }
}
