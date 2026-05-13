import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../widgets/shopping_list_card_widget.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/archive_list_usecase.dart';
import '../../domain/usecases/delete_list_usecase.dart';

class ShoppingListsScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ShoppingListsScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends ConsumerState<ShoppingListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeId = widget.homeId.isNotEmpty
        ? widget.homeId
        : ref.watch(activeHomeIdProvider).valueOrNull ?? '';
    
    if (homeId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeLists = ref.watch(activeShoppingListsProvider(homeId));
    final archivedLists = ref.watch(archivedShoppingListsProvider(homeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('قوائم التسوق'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'النشطة (${activeLists.length})'),
            Tab(text: 'المؤرشفة (${archivedLists.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListsList(activeLists, isArchived: false),
          _buildListsList(archivedLists, isArchived: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/shopping-lists/create', extra: homeId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListsList(List<dynamic> lists, {required bool isArchived}) {
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isArchived ? 'لا توجد قوائم مؤرشفة' : 'لا توجد قوائم تسوق',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isArchived
                  ? 'ستظهر هنا القوائم المؤرشفة'
                  : 'اضغط على + لإنشاء قائمة تسوق جديدة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return ShoppingListCardWidget(
          shoppingList: list,
          onTap: () => context.push('/shopping-list/${list.id}'),
          onRename: () => _showRenameDialog(context, list),
          onArchive: () => _archiveList(list.id),
          onDelete: () => _showDeleteConfirmation(context, list),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, ShoppingList list) {
    final nameController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تسمية القائمة'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'اسم القائمة',
          ),
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final repository = ref.read(shoppingListRepositoryProvider);
                await repository.updateShoppingList(
                  listId: list.id,
                  name: nameController.text,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveList(String listId) async {
    final repository = ref.read(shoppingListRepositoryProvider);
    final useCase = ArchiveListUseCase(repository);
    await useCase(listId: listId);
  }

  void _showDeleteConfirmation(BuildContext context, ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القائمة'),
        content: Text('هل أنت متأكد من حذف "${list.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repository = ref.read(shoppingListRepositoryProvider);
              final useCase = DeleteListUseCase(repository);
              await useCase(listId: list.id);
              if (mounted) Navigator.pop(context);
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
