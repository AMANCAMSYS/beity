import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/unread_count_provider.dart';

class NotificationBadgeWidget extends ConsumerWidget {
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return unreadCount.when(
      loading: () => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: onTap,
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: onTap,
      ),
      data: (count) {
        if (count == 0) {
          return IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onTap,
          );
        }

        return Badge(
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(fontSize: 10),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onTap,
          ),
        );
      },
    );
  }
}
