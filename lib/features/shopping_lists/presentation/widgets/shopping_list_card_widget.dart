import 'package:flutter/material.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:beity/core/accessibility/semantics_helpers.dart';

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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BeityCard(
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
                  color: shoppingList.isArchived
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: shoppingList.isArchived
                        ? theme.colorScheme.outline.withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  shoppingList.isArchived
                      ? Icons.archive_rounded
                      : _getIconData(shoppingList.icon),
                  color: shoppingList.isArchived
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
                        color: shoppingList.isArchived
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                        decoration: shoppingList.isArchived
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        AppSpacing.gapXS,
                        Text(
                          _formatDate(shoppingList.updatedAt ?? shoppingList.createdAt, isArabic),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (shoppingList.isArchived)
                Semantics(
                  button: true,
                  label: isArabic
                      ? 'خيارات لـ ${shoppingList.name}'
                      : 'Options for ${shoppingList.name}',
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
                      PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.unarchive_rounded, size: 20, color: theme.colorScheme.primary),
                            AppSpacing.gapMD,
                            Text(isArabic ? 'استعادة' : 'Restore'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'transfer',
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_rounded, size: 20, color: theme.colorScheme.secondary),
                            AppSpacing.gapMD,
                            Text(isArabic ? 'إضافة للمخزون' : 'Add to Inventory'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error),
                            AppSpacing.gapMD,
                            Text(
                              isArabic ? 'حذف' : 'Delete',
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
                  label: isArabic 
                      ? 'خيارات إضافية لـ ${shoppingList.name}' 
                      : 'More options for ${shoppingList.name}',
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
                            Icon(Icons.edit_rounded, size: 20, color: theme.colorScheme.primary),
                            AppSpacing.gapMD,
                            Text(isArabic ? 'إعادة تسمية' : 'Rename'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive_rounded, size: 20, color: theme.colorScheme.secondary),
                            AppSpacing.gapMD,
                            Text(isArabic ? 'أرشفة' : 'Archive'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error),
                            AppSpacing.gapMD,
                            Text(
                              isArabic ? 'حذف' : 'Delete',
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

  String _formatDate(DateTime? date, bool isArabic) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return isArabic ? 'اليوم' : 'Today';
    } else if (difference.inDays == 1) {
      return isArabic ? 'أمس' : 'Yesterday';
    } else if (difference.inDays < 7) {
      return isArabic ? 'منذ ${difference.inDays} أيام' : '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'local_grocery_store':
        return Icons.local_grocery_store_outlined;
      case 'local_pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'hardware':
        return Icons.hardware_outlined;
      case 'build':
        return Icons.build_outlined;
      case 'child_care':
        return Icons.child_care_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'celebration':
        return Icons.celebration_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'cleaning_services':
        return Icons.cleaning_services_outlined;
      case 'local_florist':
        return Icons.local_florist_outlined;
      default:
        return Icons.shopping_cart_outlined;
    }
  }
}
