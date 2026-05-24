import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category_model.dart';
import '../../domain/entities/category.dart';
import '../providers/categories_provider.dart';

class CategoryCardWidget extends ConsumerWidget {
  final CategoryModel category;
  final String? homeId;
  final bool showActions;

  const CategoryCardWidget({
    super.key,
    required this.category,
    this.homeId,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustom = category.homeId != null && !category.isDefault;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              category.icon ?? '📦',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium,
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          _getTypeName(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textDirection: TextDirection.rtl,
        ),
        trailing: isCustom && showActions
            ? IconButton(
                icon: const Icon(Icons.delete,
                    size: 20, color: Colors.red),
                onPressed: () => _deleteCategory(context, ref),
              )
            : null,
      ),
    );
  }

  Color _getCategoryColor() {
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        final colorHex = category.color!.replaceAll('#', '');
        return Color(int.parse('FF$colorHex', radix: 16));
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }

  String _getTypeName() {
    switch (category.type) {
      case CategoryType.shopping:
        return 'تسوق';
      case CategoryType.inventory:
        return 'مخزون';
      case CategoryType.expense:
        return 'مصروفات';
    }
  }

  void _deleteCategory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف التصنيف',
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل أنت متأكد من حذف "${category.name}"؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(categoryNotifierProvider.notifier)
                    .deleteCategory(categoryId: category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم حذف التصنيف بنجاح',
                        textDirection: TextDirection.rtl,
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                        textDirection: TextDirection.rtl,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
