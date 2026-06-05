import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../providers/shopping_items_provider.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../data/models/item_template_model.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  final String listId;
  final String homeId;

  const QuickAddScreen({super.key, required this.listId, required this.homeId});

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
    final templatesAsync = ref.watch(itemTemplatesProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('quick_add'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: SawaTextField(
              controller: _searchController,
              hintText: context.translate('search_items_placeholder'),
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
                    .where(
                      (t) => t.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

          if (filtered.isEmpty) {
            return SawaEmptyState(
              title: context.translate('no_items'),
              message: _searchQuery.isEmpty
                  ? context.translate('no_templates_desc')
                  : context.translate('no_results_search'),
              icon: Icons.bookmark_outline_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final template = filtered[index];
              return _buildTemplateTile(context, template);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => SawaEmptyState(
          title: context.translate('error_title'),
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(itemTemplatesProvider(widget.homeId)),
        ),
      ),
    );
  }

  Widget _buildTemplateTile(BuildContext context, ItemTemplateModel template) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(Icons.replay_rounded, color: theme.colorScheme.primary),
      ),
      title: Text(
        template.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        context.translate(
          'qty_label',
          arguments: {
            'qty':
                template.defaultQuantity ==
                    template.defaultQuantity.roundToDouble()
                ? template.defaultQuantity.toInt().toString()
                : template.defaultQuantity.toStringAsFixed(1),
          },
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              context.translate(
                'usage_count_times',
                arguments: {'count': template.usageCount.toString()},
              ),
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
      onTap: () => ActionDebouncer.execute(() => _addFromTemplate(template)),
    );
  }

  Future<void> _addFromTemplate(ItemTemplateModel template) async {
    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
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
            content: Text(
              context.translate(
                'added_item_success',
                arguments: {'name': template.name},
              ),
            ),
            action: SnackBarAction(
              label: context.translate('undo'),
              onPressed: () => ActionDebouncer.execute(_undoAdd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.translate('error')}: ${ErrorFormatter.format(e, context)}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _undoAdd() async {
    if (_lastAddedItemId == null) return;

    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
      final deleteUseCase = DeleteItemUseCase(repository);
      await deleteUseCase(itemId: _lastAddedItemId!);

      if (mounted) {
        setState(() => _lastAddedItemId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('undo_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate(
                'undo_failed',
                arguments: {'error': ErrorFormatter.format(e, context)},
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
