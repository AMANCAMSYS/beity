import 'package:flutter/material.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import 'quick_add_item_bottom_sheet.dart';

class ListDetailSummaryBar extends StatelessWidget {
  final String listId;
  final String homeId;
  final double unpurchasedTotal;

  const ListDetailSummaryBar({
    super.key,
    required this.listId,
    required this.homeId,
    required this.unpurchasedTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTotal = unpurchasedTotal > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 148),
              child: FilledButton.icon(
                onPressed: () => ActionDebouncer.execute(() async {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => QuickAddItemBottomSheet(
                      listId: listId,
                      homeId: homeId,
                    ),
                  );
                }),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  context.translate('add_item'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            AppSpacing.gapMD,
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: hasTotal
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.translate('estimated_total'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            context.translate('for_unpurchased_items'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${unpurchasedTotal.toStringAsFixed(2)} ${context.translate('currency_symbol')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        context.translate('all_items_purchased'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
