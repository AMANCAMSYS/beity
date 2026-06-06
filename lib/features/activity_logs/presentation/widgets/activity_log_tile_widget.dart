import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../app/theme/app_colors.dart';
import '../../data/models/activity_log_model.dart';
import '../../domain/entities/activity_log.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../utils/activity_localizer.dart';

class ActivityLogTileWidget extends StatelessWidget {
  final ActivityLogModel log;
  final VoidCallback? onTap;

  const ActivityLogTileWidget({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _actionColor.withValues(alpha: 0.1),
        child: Icon(_actionIcon, color: _actionColor, size: 20),
      ),
      title: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: log.actorName ?? context.translate('user_label'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' '),
            TextSpan(text: log.getLocalizedDescription(context)),
          ],
        ),
      ),
      subtitle: Text(
        _formatRelativeTime(context, log.createdAt),
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      onTap: onTap,
    );
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

  String _formatRelativeTime(BuildContext context, DateTime date) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return timeago.format(date, locale: localeCode);
  }
}
