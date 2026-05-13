import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final templatesAsync = ref.watch(itemTemplatesProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة سريعة'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث في المنتجات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
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
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final template = filtered[index];
              return _buildTemplateTile(context, template);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات محفوظة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا المنتجات التي تشتريها frequently',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTile(BuildContext context, ItemTemplateModel template) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.replay_outlined,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(template.name),
      subtitle: Text(
        'الكمية الافتراضية: ${template.defaultQuantity}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${template.usageCount} مرة',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.add_circle_outline),
        ],
      ),
      onTap: () => _addFromTemplate(template),
    );
  }

  Future<void> _addFromTemplate(ItemTemplateModel template) async {
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
            content: Text('تم إضافة ${template.name}'),
            action: SnackBarAction(
              label: 'تراجع',
              onPressed: () => _undoAdd(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
