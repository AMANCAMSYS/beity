import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

class SawaEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final bool isError;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onActionPressed;

  const SawaEmptyState({
    super.key,
    required this.title,
    this.message,
    required this.icon,
    this.isError = false,
    this.actionText,
    this.onAction,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAction = onAction ?? onActionPressed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: isError
                  ? theme.colorScheme.error.withValues(alpha: 0.42)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.78,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && effectiveAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: effectiveAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
