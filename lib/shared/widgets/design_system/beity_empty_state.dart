import 'package:flutter/material.dart';

class BeityEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final bool isError;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onActionPressed;

  const BeityEmptyState({
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isError
                  ? theme.colorScheme.error.withValues(alpha: 0.5)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && (onAction != null || onActionPressed != null)) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction ?? onActionPressed,
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
