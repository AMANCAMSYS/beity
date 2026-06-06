import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

class SawaErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryText;
  final IconData icon;

  const SawaErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.retryText,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = title ?? context.translate('error_generic');
    final displayRetryText = retryText ?? context.translate('retry_action');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              displayTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(displayRetryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
