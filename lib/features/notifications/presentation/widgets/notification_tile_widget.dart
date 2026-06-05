import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_spacing.dart';
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

  String _getCategoryLabel(BuildContext context, String category) {
    switch (category) {
      case 'shopping_list':
        return context.translate('notification_category_shopping');
      case 'home_activity':
        return context.translate('notification_category_home');
      case 'invitation':
        return context.translate('notification_category_invitation');
      default:
        return context.translate('notification_category_system');
    }
  }

  String _getTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return context.translate('time_now');
    } else if (difference.inMinutes < 60) {
      return context.translate(
        'time_ago_min',
        arguments: {'count': difference.inMinutes.toString()},
      );
    } else if (difference.inHours < 24) {
      return context.translate(
        'time_ago_hour',
        arguments: {'count': difference.inHours.toString()},
      );
    } else if (difference.inDays < 7) {
      return context.translate(
        'time_ago_day',
        arguments: {'count': difference.inDays.toString()},
      );
    } else {
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat('MMM d', locale).format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadColor = theme.colorScheme.primary;
    final iconBackground = notification.isRead
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primaryContainer;

    return Semantics(
      button: onTap != null,
      label: notification.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Material(
          color: notification.isRead
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: iconBackground,
                    child: Icon(
                      _getCategoryIcon(notification.category),
                      color: notification.isRead
                          ? theme.colorScheme.onSurfaceVariant
                          : unreadColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: unreadColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          notification.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: notification.isRead
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _getTimeAgo(context, notification.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _getCategoryLabel(context, notification.category),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
