import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';

class ShoppingListTile extends ConsumerWidget {
  final String listId;
  final String listName;
  final String icon;

  const ShoppingListTile({
    super.key,
    required this.listId,
    required this.listName,
    this.icon = 'shopping_cart',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider(listId));

    return itemsAsync.when(
      data: (items) {
        final total = items.length;
        final purchased = items.where((i) => i.isPurchased).length;
        final remaining = total - purchased;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => context.push('/shopping-list/$listId'),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIconData(icon), color: Theme.of(context).primaryColor),
            ),
            title: Text(
              listName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: total == 0
                ? Text(
                    'قائمة فارغة',
                    style: TextStyle(color: Colors.grey[500]),
                  )
                : Text(
                    '$remaining متبقية من $total',
                    style: TextStyle(color: Colors.grey[600]),
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
                            color: _getProgressColor(total > 0 ? purchased / total : 0),
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
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(total > 0 ? purchased / total : 0),
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
            child: Icon(_getIconData(icon), color: Theme.of(context).primaryColor),
          ),
          title: Text(
            listName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('جاري التحميل...', style: TextStyle(color: Colors.grey[500])),
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
            child: Icon(_getIconData(icon), color: Theme.of(context).primaryColor),
          ),
          title: Text(
            listName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'home':
        return Icons.home;
      case 'hardware':
        return Icons.hardware;
      case 'build':
        return Icons.build;
      case 'child_care':
        return Icons.child_care;
      case 'pets':
        return Icons.pets;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'celebration':
        return Icons.celebration;
      case 'school':
        return Icons.school;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'local_florist':
        return Icons.local_florist;
      default:
        return Icons.shopping_cart;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }
}
