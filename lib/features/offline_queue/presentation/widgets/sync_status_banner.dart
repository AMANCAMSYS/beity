import 'package:flutter/material.dart';

class SyncStatusBanner extends StatelessWidget {
  final int pendingCount;
  final int failedCount;
  final bool isOffline;
  final VoidCallback? onRetryAll;

  const SyncStatusBanner({
    super.key,
    required this.pendingCount,
    this.failedCount = 0,
    this.isOffline = false,
    this.onRetryAll,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && failedCount == 0 && !isOffline) {
      return const SizedBox.shrink();
    }

    final color = isOffline
        ? Colors.orange
        : failedCount > 0
            ? Colors.red
            : Colors.blue;

    final message = isOffline
        ? 'أنت غير متصل - سيتم المزامنة عند الاتصال'
        : failedCount > 0
            ? 'فشلت مزامنة $failedCount عنصر'
            : '$pendingCount عنصر في انتظار المزامنة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border(
          bottom: BorderSide(color: color.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline
                ? Icons.cloud_off
                : failedCount > 0
                    ? Icons.error_outline
                    : Icons.cloud_upload_outlined,
            size: 18,
            color: color.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (failedCount > 0 && onRetryAll != null)
            TextButton(
              onPressed: onRetryAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'إعادة المحاولة',
                style: TextStyle(
                  color: color.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
