import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class ShoppingProgressBar extends StatelessWidget {
  final int purchasedCount;
  final int totalCount;
  final double progress;

  const ShoppingProgressBar({
    super.key,
    required this.purchasedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = purchasedCount == totalCount && totalCount > 0;

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
            context.translate('items_ratio', arguments: {'purchased': purchasedCount.toString(), 'total': totalCount.toString()}),
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
