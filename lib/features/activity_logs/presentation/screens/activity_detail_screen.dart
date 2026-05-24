import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../app/theme/app_colors.dart';
import '../../data/models/activity_log_model.dart';
import '../../domain/entities/activity_log.dart';

class ActivityDetailScreen extends StatelessWidget {
  final ActivityLogModel log;

  const ActivityDetailScreen({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل النشاط'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildActionSection(context),
              if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildMetadataSection(context),
              ],
              const SizedBox(height: 24),
              _buildTimestampSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _actionColor.withValues(alpha: 0.1),
              radius: 24,
              child: Icon(_actionIcon, color: _actionColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.actorName ?? 'مستخدم',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.entityType.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإجراء',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              log.action.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (log.entityName != null) ...[
              const SizedBox(height: 8),
              Text(
                log.entityName!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              log.actionDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التفاصيل',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildMetadataEntries(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetadataEntries(BuildContext context) {
    final entries = <Widget>[];
    final metadata = log.metadata!;

    if (metadata.containsKey('old_name') &&
        metadata.containsKey('new_name')) {
      entries.add(_buildBeforeAfter(
        context,
        label: 'الاسم',
        before: metadata['old_name']?.toString() ?? '',
        after: metadata['new_name']?.toString() ?? '',
      ));
    }

    if (metadata.containsKey('old_role') &&
        metadata.containsKey('new_role')) {
      entries.add(_buildBeforeAfter(
        context,
        label: 'الدور',
        before: metadata['old_role']?.toString() ?? '',
        after: metadata['new_role']?.toString() ?? '',
      ));
    }

    if (metadata.containsKey('old_values') &&
        metadata.containsKey('new_values')) {
      final oldValues =
          Map<String, dynamic>.from(metadata['old_values'] as Map);
      final newValues =
          Map<String, dynamic>.from(metadata['new_values'] as Map);

      for (final key in oldValues.keys) {
        if (oldValues[key] != newValues[key]) {
          entries.add(_buildBeforeAfter(
            context,
            label: _fieldNameToArabic(key),
            before: oldValues[key]?.toString() ?? '',
            after: newValues[key]?.toString() ?? '',
          ));
        }
      }
    }

    if (metadata.containsKey('list_name')) {
      entries.add(_buildInfoRow(
        context,
        label: 'القائمة',
        value: metadata['list_name']?.toString() ?? '',
      ));
    }

    if (metadata.containsKey('member_name')) {
      entries.add(_buildInfoRow(
        context,
        label: 'العضو',
        value: metadata['member_name']?.toString() ?? '',
      ));
    }

    return entries;
  }

  Widget _buildBeforeAfter(BuildContext context,
      {required String label, required String before, required String after}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    before,
                    style: TextStyle(
                      color: AppColors.error,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    after,
                    style: const TextStyle(color: AppColors.success),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الوقت',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              timeago.format(log.createdAt, locale: 'ar'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _formatFullDateTime(log.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDateTime(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _fieldNameToArabic(String field) {
    switch (field) {
      case 'name':
        return 'الاسم';
      case 'quantity':
        return 'الكمية';
      case 'unit_id':
        return 'الوحدة';
      case 'category_id':
        return 'التصنيف';
      case 'note':
        return 'ملاحظة';
      default:
        return field;
    }
  }

  IconData get _actionIcon {
    switch (log.action) {
      case ActionType.listCreated:
        return Icons.add_circle_outline;
      case ActionType.listRenamed:
        return Icons.edit_outlined;
      case ActionType.listArchived:
        return Icons.archive_outlined;
      case ActionType.listDeleted:
        return Icons.delete_outline;
      case ActionType.itemAdded:
        return Icons.add_shopping_cart;
      case ActionType.itemUpdated:
        return Icons.edit_note;
      case ActionType.itemPurchased:
        return Icons.check_circle_outline;
      case ActionType.itemUnpurchased:
        return Icons.undo;
      case ActionType.itemDeleted:
        return Icons.remove_shopping_cart;
      case ActionType.memberJoined:
        return Icons.person_add_outlined;
      case ActionType.memberRemoved:
        return Icons.person_remove_outlined;
      case ActionType.memberRoleChanged:
        return Icons.admin_panel_settings_outlined;
      case ActionType.invitationAccepted:
        return Icons.mark_email_read_outlined;
      case ActionType.aiItemsAdded:
        return Icons.auto_awesome;
    }
  }

  Color get _actionColor {
    switch (log.action) {
      case ActionType.listCreated:
        return AppColors.success;
      case ActionType.listRenamed:
        return AppColors.info;
      case ActionType.listArchived:
        return AppColors.warning;
      case ActionType.listDeleted:
        return AppColors.error;
      case ActionType.itemAdded:
        return AppColors.success;
      case ActionType.itemUpdated:
        return AppColors.info;
      case ActionType.itemPurchased:
        return AppColors.primary;
      case ActionType.itemUnpurchased:
        return AppColors.warning;
      case ActionType.itemDeleted:
        return AppColors.error;
      case ActionType.memberJoined:
        return AppColors.success;
      case ActionType.memberRemoved:
        return AppColors.error;
      case ActionType.memberRoleChanged:
        return AppColors.secondary;
      case ActionType.invitationAccepted:
        return AppColors.success;
      case ActionType.aiItemsAdded:
        return AppColors.accent;
    }
  }
}
