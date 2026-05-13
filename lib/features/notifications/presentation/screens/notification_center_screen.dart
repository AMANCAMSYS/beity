import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notifications_provider.dart';
import '../providers/unread_count_provider.dart';
import '../widgets/notification_tile_widget.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          unreadCount.whenOrNull(
                data: (count) => count > 0
                    ? TextButton(
                        onPressed: () {
                          ref
                              .read(notificationsProvider.notifier)
                              .markAllAsRead();
                          ref.read(unreadCountProvider.notifier).reset();
                        },
                        child: const Text('Mark all read'),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading notifications: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when\nsomeone adds items or invites you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.builder(
              itemCount: notifications.length +
                  (ref.read(notificationsProvider.notifier).hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  // Load more indicator
                  if (!ref
                      .read(notificationsProvider.notifier)
                      .isLoadingMore) {
                    ref.read(notificationsProvider.notifier).loadMore();
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notification = notifications[index];
                return NotificationTileWidget(
                  notification: notification,
                  onTap: () {
                    // Mark as read
                    if (!notification.isRead) {
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead([notification.id]);
                      ref.read(unreadCountProvider.notifier).decrement(1);
                    }

                    // Navigate to target
                    if (notification.targetRoute != null) {
                      context.go(notification.targetRoute!);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
