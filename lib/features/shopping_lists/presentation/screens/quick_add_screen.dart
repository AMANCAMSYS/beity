import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../providers/shopping_items_provider.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../data/models/item_template_model.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  final String listId;
  final String homeId;

  const QuickAddScreen({
    super.key,
    required this.listId,
    required this.homeId,
  });

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _lastAddedItemId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final templatesAsync = ref.watch(itemTemplatesProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إضافة سريعة' : 'Quick Add', style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: BeityTextField(
              controller: _searchController,
              hintText: isArabic ? 'بحث في المنتجات...' : 'Search items...',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: templatesAsync.when(
        data: (templates) {
          final filtered = _searchQuery.isEmpty
              ? templates
              : templates
                  .where((t) =>
                      t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          if (filtered.isEmpty) {
            return BeityEmptyState(
              title: isArabic ? 'لا توجد منتجات' : 'No Items Found',
              message: _searchQuery.isEmpty 
                  ? (isArabic ? 'ستظهر هنا المنتجات التي تشتريها بكثرة' : 'Products you buy frequently will appear here')
                  : (isArabic ? 'لم يتم العثور على نتائج للبحث' : 'No results found for your search'),
              icon: Icons.bookmark_outline_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final template = filtered[index];
              return _buildTemplateTile(context, template, isArabic);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => BeityEmptyState(
          title: isArabic ? 'حدث خطأ' : 'An error occurred',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: isArabic ? 'إعادة المحاولة' : 'Retry',
          onAction: () => ref.invalidate(itemTemplatesProvider(widget.homeId)),
        ),
      ),
    );
  }

  Widget _buildTemplateTile(BuildContext context, ItemTemplateModel template, bool isArabic) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(
          Icons.replay_rounded,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        template.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        isArabic ? 'الكمية: ${template.defaultQuantity}' : 'Qty: ${template.defaultQuantity}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              isArabic ? '${template.usageCount} مرة' : '${template.usageCount}x',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppSpacing.gapSM,
          Icon(
            Icons.add_circle_outline_rounded,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
      onTap: () => ActionDebouncer.execute(() => _addFromTemplate(template, isArabic)),
    );
  }

  Future<void> _addFromTemplate(ItemTemplateModel template, bool isArabic) async {
    try {
      final repository = ref.read(shoppingItemRepositoryProvider);
      final addItemUseCase = AddItemUseCase(repository);

      final item = await addItemUseCase(
        listId: widget.listId,
        homeId: widget.homeId,
        name: template.name,
        quantity: template.defaultQuantity,
        unitId: template.defaultUnitId,
        categoryId: template.defaultCategoryId,
        skipDuplicateCheck: true,
      );

      await repository.incrementTemplateUsage(templateId: template.id);

      if (mounted) {
        setState(() => _lastAddedItemId = item.id);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم إضافة ${template.name}' : 'Added ${template.name}'),
            action: SnackBarAction(
              label: isArabic ? 'تراجع' : 'Undo',
              onPressed: () => ActionDebouncer.execute(_undoAdd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _undoAdd() async {
    if (_lastAddedItemId == null) return;

    try {
      final repository = ref.read(shoppingItemRepositoryProvider);
      final deleteUseCase = DeleteItemUseCase(repository);
      await deleteUseCase(itemId: _lastAddedItemId!);

      if (mounted) {
        setState(() => _lastAddedItemId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التراجع')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التراجع: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
