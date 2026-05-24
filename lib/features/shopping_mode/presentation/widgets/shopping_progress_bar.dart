import 'package:flutter/material.dart';

class ShoppingProgressBar extends StatelessWidget {
  final int purchasedCount;
  final int totalCount;

  const ShoppingProgressBar({
    super.key,
    required this.purchasedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalCount > 0 ? purchasedCount / totalCount : 0.0;
    final isComplete = purchasedCount == totalCount && totalCount > 0;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isArabic ? '$purchasedCount من $totalCount' : '$purchasedCount of $totalCount',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isComplete
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
