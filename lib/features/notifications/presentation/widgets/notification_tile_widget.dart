import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';

import '../../domain/entities/notification.dart';

class NotificationTileWidget extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTileWidget({
    super.key,
    required this.notification,
    this.onTap,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'shopping_list':
        return Icons.shopping_cart;
      case 'home_activity':
        return Icons.home;
      case 'invitation':
        return Icons.mail;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return context.translate('time_now');
    } else if (difference.inMinutes < 60) {
      return context.translate('time_ago_min', arguments: {'count': difference.inMinutes.toString()});
    } else if (difference.inHours < 24) {
      return context.translate('time_ago_hour', arguments: {'count': difference.inHours.toString()});
    } else if (difference.inDays < 7) {
      return context.translate('time_ago_day', arguments: {'count': difference.inDays.toString()});
    } else {
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat('MMM d', locale).format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? Colors.grey.shade200
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _getCategoryIcon(notification.category),
          color: notification.isRead
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: notification.isRead ? Colors.grey : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getTimeAgo(context, notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
