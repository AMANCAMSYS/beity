import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../../core/utils/action_debouncer.dart';

class AiListSelectorSheet extends ConsumerWidget {
  final String homeId;

  const AiListSelectorSheet({super.key, required this.homeId});

  static Future<void> show(BuildContext context, String homeId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiListSelectorSheet(homeId: homeId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(activeShoppingListsProvider(homeId));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapLG,
            Text(
              isArabic ? 'اختر قائمة للحصول على اقتراحات' : 'Select a list for suggestions',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.gapSM,
            Text(
              isArabic 
                  ? 'سيقوم المساعد الذكي بتحليل محتوى القائمة المختارة وتقديم اقتراحات مخصصة.' 
                  : 'The AI assistant will analyze the selected list and provide personalized suggestions.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            AppSpacing.gapLG,
            if (lists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                      AppSpacing.gapMD,
                      Text(
                        isArabic ? 'لا توجد قوائم تسوق نشطة' : 'No active shopping lists',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(Icons.list_alt_rounded, color: theme.colorScheme.primary),
                      ),
                      title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        ActionDebouncer.execute(() async {
                          final items = await ref.read(shoppingItemsProvider(list.id).future);
                          final existingItemNames = items.map((e) => e.name).toList();
                          
                          if (context.mounted) {
                            context.push('/shopping-list/${list.id}/ai-suggestions', extra: {
                              'listId': list.id,
                              'listTitle': list.name,
                              'homeId': list.homeId,
                              'homeType': 'family',
                              'existingItemNames': existingItemNames,
                            });
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            AppSpacing.gapLG,
          ],
        ),
      ),
    );
  }
}
