import 'package:flutter/material.dart';
import 'package:beity/core/localization/app_localizations.dart';

class ErrorScreen extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final VoidCallback? onReport;
  final String? retryLabel;
  final String? reportLabel;

  const ErrorScreen({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.onReport,
    this.retryLabel,
    this.reportLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: context.translate('error_icon'),
              child: Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              Semantics(
                button: true,
                label: retryLabel ?? context.translate('retry'),
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel ?? context.translate('retry')),
                ),
              ),
            if (onReport != null) ...[
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: reportLabel ?? context.translate('report_issue'),
                child: OutlinedButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.bug_report),
                  label: Text(reportLabel ?? context.translate('report_issue')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
