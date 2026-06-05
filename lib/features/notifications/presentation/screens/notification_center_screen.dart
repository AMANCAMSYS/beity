import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/feature_route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_empty_state.dart';
import '../../../../shared/widgets/design_system/sawa_loading_state.dart';
import '../../domain/entities/notification.dart';
import '../providers/notifications_provider.dart';
import '../providers/unread_count_provider.dart';
import '../widgets/notification_tile_widget.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  late final ScrollController _scrollController;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final notifier = ref.read(notificationsProvider.notifier);
    if (!notifier.hasMore || notifier.isLoadingMore) return;

    final remaining =
        _scrollController.position.maxScrollExtent - _scrollController.offset;
    if (remaining < 360) {
      notifier.loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(unreadCountProvider);
    ref.invalidate(notificationsProvider);
    await ref.read(notificationsProvider.future);
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAllRead = true);
    try {
      await ref.read(notificationsProvider.notifier).markAllAsRead();
      ref.read(unreadCountProvider.notifier).reset();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.translate(
              'mark_notifications_read_failed',
              arguments: {'error': error.toString()},
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _openNotificationTarget(String? targetRoute) async {
    if (targetRoute == null || targetRoute.isEmpty) return;
    if (!targetRoute.startsWith('/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.translate('notification_target_missing')),
        ),
      );
      return;
    }
    await context.push(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final filter = ref.watch(notificationFeedFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('notifications')),
        actions: [
          IconButton(
            tooltip: context.translate('notification_settings'),
            icon: const Icon(Icons.tune_rounded),
            onPressed: () =>
                context.push(FeatureRoutePaths.notificationPreferences),
          ),
          unreadCount.whenOrNull(
                data: (count) => count > 0
                    ? TextButton(
                        onPressed: _isMarkingAllRead ? null : _markAllAsRead,
                        child: Text(context.translate('mark_all_read')),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => SawaLoadingState(
          message: context.translate('loading_notifications'),
        ),
        error: (error, stack) => SawaEmptyState(
          icon: Icons.notifications_off_rounded,
          isError: true,
          title: context.translate('failed_load_notifications_history'),
          message: context.translate(
            'error_loading_notifications',
            arguments: {'error': error.toString()},
          ),
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Column(
              children: [
                _NotificationFilterBar(selectedFilter: filter),
                Expanded(
                  child: SawaEmptyState(
                    icon: filter == NotificationFeedFilter.unread
                        ? Icons.mark_email_read_rounded
                        : Icons.notifications_none_rounded,
                    title: filter == NotificationFeedFilter.unread
                        ? context.translate('no_unread_notifications')
                        : context.translate('no_notifications_yet'),
                    message: filter == NotificationFeedFilter.unread
                        ? context.translate('no_unread_notifications_desc')
                        : context.translate('notifications_empty_desc'),
                  ),
                ),
              ],
            );
          }

          final feedItems = _buildNotificationFeedItems(notifications);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _NotificationFilterBar(selectedFilter: filter),
                ),
                SliverList.builder(
                  itemCount: feedItems.length,
                  itemBuilder: (context, index) {
                    final item = feedItems[index];
                    return switch (item) {
                      _SingleNotificationFeedItem(:final notification) =>
                        NotificationTileWidget(
                          notification: notification,
                          onTap: () async {
                            if (!notification.isRead) {
                              await ref
                                  .read(notificationsProvider.notifier)
                                  .markAsRead([notification.id]);
                              ref
                                  .read(unreadCountProvider.notifier)
                                  .decrement(1);
                            }

                            await _openNotificationTarget(
                              notification.targetRoute,
                            );
                          },
                        ),
                      _GroupedNotificationFeedItem(:final notifications) =>
                        _GroupedNotificationTile(
                          notifications: notifications,
                          onTap: () async {
                            final unreadIds = notifications
                                .where((n) => !n.isRead)
                                .map((n) => n.id)
                                .toList();
                            if (unreadIds.isNotEmpty) {
                              await ref
                                  .read(notificationsProvider.notifier)
                                  .markAsRead(unreadIds);
                              ref
                                  .read(unreadCountProvider.notifier)
                                  .decrement(unreadIds.length);
                            }

                            await _openNotificationTarget(
                              _targetRouteForGroup(notifications),
                            );
                          },
                        ),
                    };
                  },
                ),
                SliverToBoxAdapter(child: _LoadMoreFooter()),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_NotificationFeedItem> _buildNotificationFeedItems(
    List<AppNotification> notifications,
  ) {
    final grouped = <String, List<AppNotification>>{};
    final orderedKeys = <String>[];
    final items = <_NotificationFeedItem>[];

    for (final notification in notifications) {
      if (!_shouldGroupNotification(notification)) {
        items.add(_SingleNotificationFeedItem(notification));
        continue;
      }

      final key = '${notification.homeId}:${notification.category}';
      grouped
          .putIfAbsent(key, () {
            orderedKeys.add(key);
            return [];
          })
          .add(notification);
    }

    for (final key in orderedKeys) {
      final group = grouped[key]!;
      if (group.length == 1) {
        items.add(_SingleNotificationFeedItem(group.first));
      } else {
        items.add(_GroupedNotificationFeedItem(group));
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  bool _shouldGroupNotification(AppNotification notification) {
    return !notification.isRead &&
        (notification.category == 'task' ||
            notification.type == 'task_assigned');
  }

  String? _targetRouteForGroup(List<AppNotification> notifications) {
    if (notifications.isEmpty) return null;
    final first = notifications.first;
    if (first.category == 'task' || first.type == 'task_assigned') {
      return FeatureRoutePaths.tasks(first.homeId);
    }
    return first.targetRoute;
  }
}

sealed class _NotificationFeedItem {
  DateTime get createdAt;
}

class _SingleNotificationFeedItem extends _NotificationFeedItem {
  final AppNotification notification;

  _SingleNotificationFeedItem(this.notification);

  @override
  DateTime get createdAt => notification.createdAt;
}

class _GroupedNotificationFeedItem extends _NotificationFeedItem {
  final List<AppNotification> notifications;

  _GroupedNotificationFeedItem(this.notifications);

  @override
  DateTime get createdAt => notifications.first.createdAt;
}

class _GroupedNotificationTile extends StatelessWidget {
  final List<AppNotification> notifications;
  final VoidCallback? onTap;

  const _GroupedNotificationTile({required this.notifications, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final preview = notifications.take(2).map((n) => n.body).join('\n');

    return Semantics(
      button: onTap != null,
      label: context.translate(
        'notification_group_tasks_title',
        arguments: {'count': unreadCount.toString()},
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Material(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
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
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.assignment_ind_outlined,
                      color: theme.colorScheme.primary,
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
                                context.translate(
                                  'notification_group_tasks_title',
                                  arguments: {'count': unreadCount.toString()},
                                ),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          preview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.translate(
                            'notification_group_tasks_desc',
                            arguments: {'count': unreadCount.toString()},
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
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

class _NotificationFilterBar extends ConsumerWidget {
  final NotificationFeedFilter selectedFilter;

  const _NotificationFilterBar({required this.selectedFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: SegmentedButton<NotificationFeedFilter>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: NotificationFeedFilter.all,
            label: Text(context.translate('all_notifications')),
            icon: const Icon(Icons.notifications_rounded),
          ),
          ButtonSegment(
            value: NotificationFeedFilter.unread,
            label: Text(context.translate('unread_notifications')),
            icon: const Icon(Icons.mark_email_unread_rounded),
          ),
        ],
        selected: {selectedFilter},
        onSelectionChanged: (selection) {
          ref.read(notificationFeedFilterProvider.notifier).state =
              selection.first;
        },
      ),
    );
  }
}

class _LoadMoreFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(notificationsProvider.notifier);
    final error = notifier.loadMoreError;

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).loadMore(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.translate('retry')),
          ),
        ),
      );
    }

    if (!notifier.hasMore) {
      return const SizedBox(height: AppSpacing.lg);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: notifier.isLoadingMore
            ? const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const SizedBox(height: AppSpacing.md),
      ),
    );
  }
}
