import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/shopping_route_paths.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/shopping_ui_utils.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';

class ShoppingListTile extends ConsumerWidget {
  final String homeId;
  final String listId;
  final String listName;
  final String icon;

  const ShoppingListTile({
    super.key,
    required this.homeId,
    required this.listId,
    required this.listName,
    this.icon = 'shopping_cart',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summariesAsync = ref.watch(shoppingListSummariesProvider(homeId));

    return summariesAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (summaries) {
        final summary =
            summaries[listId] ?? ShoppingListSummary(total: 0, purchased: 0);
        final total = summary.total;
        final purchased = summary.purchased;
        final remaining = summary.remaining;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => context.push(ShoppingRoutePaths.detail(listId)),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                ShoppingUiUtils.getIconData(icon, style: IconStyle.plain),
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              listName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: total == 0
                ? Text(
                    context.translate('list_empty'),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  )
                : Text(
                    context.translate(
                      'items_remaining_count',
                      arguments: {
                        'remaining': remaining.toString(),
                        'total': total.toString(),
                      },
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
            trailing: total > 0
                ? SizedBox(
                    width: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${total > 0 ? ((purchased / total) * 100).round() : 0}%',
                          style: TextStyle(
                            color: ShoppingUiUtils.getProgressColor(
                              total > 0 ? purchased / total : 0,
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? purchased / total : 0,
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.6),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ShoppingUiUtils.getProgressColor(
                                total > 0 ? purchased / total : 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
      loading: () => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ShoppingUiUtils.getIconData(icon, style: IconStyle.plain),
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            listName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            context.translate('loading'),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
      error: (_, _) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ShoppingUiUtils.getIconData(icon, style: IconStyle.plain),
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            listName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
