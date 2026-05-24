import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/activity_log_model.dart';
import '../../domain/entities/activity_log.dart';

class ActivityLogTileWidget extends StatelessWidget {
  final ActivityLogModel log;
  final VoidCallback? onTap;

  const ActivityLogTileWidget({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _actionColor.withValues(alpha: 0.1),
          child: Icon(_actionIcon, color: _actionColor, size: 20),
        ),
        title: RichText(
          textDirection: TextDirection.rtl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: log.actorName ?? 'مستخدم',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' '),
              TextSpan(text: log.actionDescription),
            ],
          ),
        ),
        subtitle: Text(
          _formatRelativeTime(log.createdAt),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        onTap: onTap,
      ),
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
        return Colors.green;
      case ActionType.listRenamed:
        return Colors.blue;
      case ActionType.listArchived:
        return Colors.orange;
      case ActionType.listDeleted:
        return Colors.red;
      case ActionType.itemAdded:
        return Colors.green;
      case ActionType.itemUpdated:
        return Colors.blue;
      case ActionType.itemPurchased:
        return Colors.teal;
      case ActionType.itemUnpurchased:
        return Colors.amber;
      case ActionType.itemDeleted:
        return Colors.red;
      case ActionType.memberJoined:
        return Colors.green;
      case ActionType.memberRemoved:
        return Colors.red;
      case ActionType.memberRoleChanged:
        return Colors.purple;
      case ActionType.invitationAccepted:
        return Colors.green;
      case ActionType.aiItemsAdded:
        return Colors.purple;
    }
  }

  String _formatRelativeTime(DateTime date) {
    return timeago.format(date, locale: 'ar');
  }
}
