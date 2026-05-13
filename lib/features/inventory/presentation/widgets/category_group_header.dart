import 'package:flutter/material.dart';

class CategoryGroupHeader extends StatelessWidget {
  final String? categoryName;
  final int itemCount;

  const CategoryGroupHeader({
    super.key,
    this.categoryName,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = categoryName ?? 'بدون تصنيف';
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$itemCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
            ),
          ),
        ],
      ),
    );
  }
}
