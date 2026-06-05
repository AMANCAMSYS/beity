import 'package:flutter/material.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/utils/shopping_ui_utils.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/core/accessibility/semantics_helpers.dart';

class ShoppingListCardWidget extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onRestore;
  final VoidCallback? onTransferToInventory;

  const ShoppingListCardWidget({
    super.key,
    required this.shoppingList,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onRename,
    this.onRestore,
    this.onTransferToInventory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArchived = shoppingList.isArchived;
    final isCompleted = shoppingList.status == ShoppingListStatus.completed;
    final isInactive = isArchived || isCompleted;

    return SawaCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Semantics(
        label: AccessibilityHelpers.shoppingListLabel(
          name: shoppingList.name,
          itemCount: shoppingList.itemCount,
          purchasedCount: shoppingList.purchasedCount,
        ),
        button: true,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isInactive
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: isInactive
                        ? theme.colorScheme.outline.withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  isArchived
                      ? Icons.archive_rounded
                      : isCompleted
                      ? Icons.task_alt_rounded
                      : ShoppingUiUtils.getIconData(shoppingList.icon, style: IconStyle.outlined),
                  color: isInactive
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                  size: 26,
                ),
              ),
              AppSpacing.gapLG,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoppingList.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isInactive
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                        decoration: isArchived
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (shoppingList.description != null &&
                        shoppingList.description!.isNotEmpty) ...[
                      AppSpacing.gapXS,
                      Text(
                        shoppingList.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    AppSpacing.gapXS,
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        AppSpacing.gapXS,
                        Text(
                          _formatDate(
                            shoppingList.updatedAt ?? shoppingList.createdAt,
                            context,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isInactive)
                Semantics(
                  button: true,
                  label: context.translate(
                    'options_for_list',
                    arguments: {'name': shoppingList.name},
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'restore':
                          onRestore?.call();
                          break;
                        case 'transfer':
                          onTransferToInventory?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (isArchived)
                        PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(
                                Icons.unarchive_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              AppSpacing.gapMD,
                              Text(context.translate('restore')),
                            ],
                          ),
                        ),
                      if (isCompleted ||
                          shoppingList.inventoryTransferredAt != null)
                        PopupMenuItem(
                          value: 'transfer',
                          enabled: shoppingList.canTransferToInventory,
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                size: 20,
                                color: shoppingList.canTransferToInventory
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                              ),
                              AppSpacing.gapMD,
                              Text(
                                shoppingList.canTransferToInventory
                                    ? context.translate('add_to_inventory')
                                    : context.translate('added_to_inventory'),
                                style: TextStyle(
                                  color: shoppingList.canTransferToInventory
                                      ? null
                                      : theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                            AppSpacing.gapMD,
                            Text(
                              context.translate('delete'),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Semantics(
                  button: true,
                  label: context.translate(
                    'more_options_for_list',
                    arguments: {'name': shoppingList.name},
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          onRename?.call();
                          break;
                        case 'archive':
                          onArchive?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            AppSpacing.gapMD,
                            Text(context.translate('rename')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              Icons.archive_rounded,
                              size: 20,
                              color: theme.colorScheme.secondary,
                            ),
                            AppSpacing.gapMD,
                            Text(context.translate('archive')),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                            AppSpacing.gapMD,
                            Text(
                              context.translate('delete'),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return context.translate('today');
    } else if (difference.inDays == 1) {
      return context.translate('yesterday');
    } else if (difference.inDays < 7) {
      return context.translate(
        'days_ago',
        arguments: {'count': difference.inDays.toString()},
      );
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
