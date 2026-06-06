import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shopping_items_provider.dart';
import '../../widgets/presence_indicator_widget.dart';

class IsolatedPresenceIndicatorWidget extends ConsumerWidget {
  final String listId;
  final String currentUserId;
  const IsolatedPresenceIndicatorWidget({
    super.key,
    required this.listId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceAsync = ref.watch(presenceProvider(listId));
    return presenceAsync.when(
      data: (presences) => PresenceIndicatorWidget(
        presences: presences,
        currentUserId: currentUserId,
      ),
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
