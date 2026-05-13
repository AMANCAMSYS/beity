import 'package:flutter/material.dart';
import '../../domain/entities/shopping_list.dart';
import '../../../../core/accessibility/semantics_helpers.dart';

class ShoppingListCardWidget extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  const ShoppingListCardWidget({
    super.key,
    required this.shoppingList,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Semantics(
        label: AccessibilityHelpers.shoppingListLabel(
          name: shoppingList.name,
          itemCount: shoppingList.itemCount ?? 0,
          purchasedCount: shoppingList.purchasedCount ?? 0,
        ),
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: shoppingList.isArchived
                        ? Colors.grey.withValues(alpha: 0.2)
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    shoppingList.isArchived
                        ? Icons.archive_outlined
                        : Icons.shopping_cart_outlined,
                    color: shoppingList.isArchived
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shoppingList.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: shoppingList.isArchived
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (shoppingList.description != null &&
                          shoppingList.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          shoppingList.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(shoppingList.updatedAt ?? shoppingList.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!shoppingList.isArchived)
                  Semantics(
                    button: true,
                    label: 'More options for ${shoppingList.name}',
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
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
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('إعادة تسمية'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('أرشفة'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('حذف', style: TextStyle(color: Colors.red)),
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
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
