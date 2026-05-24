import 'package:flutter/material.dart';

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
              label: 'أيقونة خطأ',
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
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              Semantics(
                button: true,
                label: retryLabel ?? 'إعادة المحاولة',
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel ?? 'إعادة المحاولة'),
                ),
              ),
            if (onReport != null) ...[
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: reportLabel ?? 'الإبلاغ عن مشكلة',
                child: OutlinedButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.bug_report),
                  label: Text(reportLabel ?? 'الإبلاغ عن مشكلة'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
