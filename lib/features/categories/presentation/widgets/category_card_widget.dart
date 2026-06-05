import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../../../core/errors/error_formatter.dart';
import '../../../../app/theme/app_colors.dart';
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
            color: _getCategoryColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getCategoryAbbreviation(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getCategoryColor(),
              ),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium,
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          _getTypeName(context),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textDirection: TextDirection.rtl,
        ),
        trailing: isCustom && showActions
            ? IconButton(
                icon: const Icon(Icons.delete,
                    size: 20, color: AppColors.error),
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

  String _getTypeName(BuildContext context) {
    switch (category.type) {
      case CategoryType.shopping:
        return context.translate('shopping');
      case CategoryType.inventory:
        return context.translate('inventory_filter');
      case CategoryType.expense:
        return context.translate('expense');
    }
  }

  String _getCategoryAbbreviation() {
    final name = category.name.trim();
    if (name.isEmpty) return '??';

    // Check if the name starts with Arabic characters
    final isArabic = RegExp(r'^[\u0600-\u06FF]').hasMatch(name);

    if (isArabic) {
      final words = name.split(RegExp(r'\s+'));
      if (words.length >= 2) {
        // Take first letter of first word and first letter of second word (e.g. "خ ف" for "خضروات وفواكه")
        final first = words[0].substring(0, 1);
        final second = words[1].substring(0, 1);
        return '$first $second';
      } else {
        // Take the first two letters of the single word (e.g. "من" for "منظفات")
        return name.length >= 2 ? name.substring(0, 2) : name;
      }
    } else {
      // Latin script (English, Turkish, etc.)
      final words = name.split(RegExp(r'\s+'));
      if (words.length >= 2) {
        final first = words[0].substring(0, 1).toUpperCase();
        final second = words[1].substring(0, 1).toUpperCase();
        return '$first$second';
      } else {
        return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
      }
    }
  }

  void _deleteCategory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.translate('delete_category'),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          context.translate('delete_category_confirm', arguments: {'name': category.name}),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(categoryNotifierProvider.notifier)
                    .deleteCategory(categoryId: category.id);
                if (context.mounted) {
                  SawaSnackBar.success(context, context.translate('category_deleted_success'));
                }
              } catch (e) {
                if (context.mounted) {
                  SawaSnackBar.error(
                    context,
                    ErrorFormatter.format(e, context),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.translate('delete')),
          ),
        ],
      ),
    );
  }
}
