import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
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
            _getTimeAgo(notification.createdAt),
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
