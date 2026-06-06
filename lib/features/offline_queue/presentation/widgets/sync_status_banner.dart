import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

import '../../../../app/theme/app_colors.dart';

class SyncStatusBanner extends StatelessWidget {
  final int pendingCount;
  final int failedCount;
  final bool isOffline;
  final bool canSyncNow;
  final VoidCallback? onRetryAll;

  const SyncStatusBanner({
    super.key,
    required this.pendingCount,
    this.failedCount = 0,
    this.isOffline = false,
    this.canSyncNow = true,
    this.onRetryAll,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && failedCount == 0 && !isOffline) {
      return const SizedBox.shrink();
    }

    final isPausedForWifi = !isOffline && !canSyncNow && pendingCount > 0;

    final color = isOffline || isPausedForWifi
        ? AppColors.warning
        : failedCount > 0
        ? AppColors.error
        : AppColors.info;
    final backgroundColor = isOffline || isPausedForWifi
        ? AppColors.warningContainer
        : failedCount > 0
        ? AppColors.errorContainer
        : AppColors.infoContainer;

    final message = isOffline
        ? context.translate('sync_banner_offline')
        : isPausedForWifi
        ? context.translate('sync_banner_wifi_paused')
        : failedCount > 0
        ? context.translate(
            'sync_banner_failed_count',
            arguments: {'count': failedCount.toString()},
          )
        : context.translate(
            'sync_banner_pending_count',
            arguments: {'count': pendingCount.toString()},
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.28)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline || isPausedForWifi
                ? Icons.cloud_off
                : failedCount > 0
                ? Icons.error_outline
                : Icons.cloud_upload_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
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
                context.translate('retry'),
                style: TextStyle(
                  color: color,
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
