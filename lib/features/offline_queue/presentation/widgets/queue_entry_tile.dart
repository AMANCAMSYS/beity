import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/sync_status.dart';

class QueueEntryTile extends StatelessWidget {
  final QueueEntry entry;
  final VoidCallback? onRetry;

  const QueueEntryTile({super.key, required this.entry, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeadingIcon(),
      title: Text(
        context.translate(entry.actionType.translationKey, fallback: entry.actionType.displayName),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${context.translate(entry.entityType.translationKey, fallback: entry.entityType.displayName)} - ${entry.entityId}',
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildLeadingIcon() {
    switch (entry.syncStatus) {
      case SyncStatus.pending:
        return const Icon(
          Icons.cloud_upload_outlined,
          color: AppColors.warning,
        );
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.failed:
        return const Icon(Icons.error_outline, color: AppColors.error);
    }
  }

  Widget? _buildTrailing(BuildContext context) {
    if (entry.isFailed && onRetry != null) {
      return TextButton(
        onPressed: onRetry,
        child: Text(context.translate('retry', fallback: 'Retry')),
      );
    }
    return null;
  }
}
