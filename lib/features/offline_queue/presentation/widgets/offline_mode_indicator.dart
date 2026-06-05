import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

import '../../../../app/theme/app_colors.dart';

class OfflineModeIndicator extends StatelessWidget {
  final int? pendingCount;

  const OfflineModeIndicator({super.key, this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(
            context.translate('offline'),
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          if (pendingCount != null && pendingCount! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
