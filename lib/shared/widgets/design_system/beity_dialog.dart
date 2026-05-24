import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

class BeityDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;

  const BeityDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BeityDialog(
        title: title,
        message: message,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: content ?? (message != null ? Text(message!) : null),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            child: Text(cancelText!),
          ),
        if (confirmText != null)
          ElevatedButton(
            onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
            style: isDestructive
                ? ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error)
                : null,
            child: Text(confirmText!),
          ),
      ],
    );
  }
}
