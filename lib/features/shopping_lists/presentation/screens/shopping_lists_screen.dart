import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../widgets/shopping_list_card_widget.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/archive_list_usecase.dart';
import '../../domain/usecases/archive_list_usecase.dart';
import '../../domain/usecases/delete_list_usecase.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../core/config/feature_flags.dart';
import 'package:beity/features/ai_suggestions/presentation/widgets/ai_list_selector_sheet.dart';

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
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final homeId = widget.homeId.isNotEmpty
        ? widget.homeId
        : ref.watch(activeHomeIdProvider).valueOrNull ?? '';
    
    if (homeId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final listsAsync = ref.watch(shoppingListsProvider(homeId));
    final activeLists = ref.watch(activeShoppingListsProvider(homeId));
    final archivedLists = ref.watch(archivedShoppingListsProvider(homeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'قوائم التسوق' : 'Shopping Lists'),
        centerTitle: true,
        actions: [
          if (FeatureFlags.enableAi)
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent),
              onPressed: () => AiListSelectorSheet.show(context, homeId),
              tooltip: isArabic ? 'المساعد الذكي' : 'AI Assistant',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: theme.textTheme.titleSmall,
          tabs: [
            Tab(text: isArabic ? 'النشطة (${activeLists.length})' : 'Active (${activeLists.length})'),
            Tab(text: isArabic ? 'المؤرشفة (${archivedLists.length})' : 'Archived (${archivedLists.length})'),
          ],
        ),
      ),
      body: listsAsync.when(
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _buildListsList(activeLists, homeId: homeId, isArchived: false, isArabic: isArabic),
            _buildListsList(archivedLists, homeId: homeId, isArchived: true, isArabic: isArabic),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => BeityEmptyState(
          title: isArabic ? 'عذراً، حدث خطأ' : 'Error loading lists',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
          onAction: () => ref.invalidate(shoppingListsProvider(homeId)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ActionDebouncer.execute(() => context.push('/shopping-lists/create', extra: homeId)),
        label: Text(isArabic ? 'قائمة جديدة' : 'New List'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildListsList(List<dynamic> lists, {required String homeId, required bool isArchived, required bool isArabic}) {
    final theme = Theme.of(context);

    if (lists.isEmpty) {
      return BeityEmptyState(
        title: isArchived 
            ? (isArabic ? 'لا توجد قوائم مؤرشفة' : 'No archived lists') 
            : (isArabic ? 'لا توجد قوائم تسوق' : 'No shopping lists'),
        message: isArchived
            ? (isArabic 
                ? 'ستظهر هنا القوائم التي قمت بأرشفتها للحفاظ على ترتيب شاشتك الرئيسية.' 
                : 'Lists you archive to keep your main screen organized will appear here.')
            : (isArabic 
                ? 'ابدأ بإنشاء أول قائمة لتنظيم مشترياتك وإدارتها مع عائلتك بكل سهولة.' 
                : 'Start by creating your first list to organize your purchases easily.'),
        icon: isArchived ? Icons.archive_outlined : Icons.shopping_bag_outlined,
        actionText: !isArchived ? (isArabic ? 'إنشاء أول قائمة' : 'Create First List') : null,
        onAction: !isArchived 
            ? () => ActionDebouncer.execute(() => context.push('/shopping-lists/create', extra: homeId))
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(shoppingListsProvider(homeId)),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: lists.length,
        itemBuilder: (context, index) {
          final list = lists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ShoppingListCardWidget(
              shoppingList: list,
              onTap: () => ActionDebouncer.execute(() async => context.push('/shopping-list/${list.id}')),
              onRename: () => ActionDebouncer.execute(() async => _showRenameDialog(context, list, isArabic)),
              onArchive: () => ActionDebouncer.execute(() async => _archiveList(list.id)),
              onDelete: () => ActionDebouncer.execute(() async => _showDeleteConfirmation(context, list, isArabic)),
            ),
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ShoppingList list, bool isArabic) {
    final nameController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'إعادة تسمية القائمة' : 'Rename List', textAlign: TextAlign.center),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        contentPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        content: BeityTextField(
          controller: nameController,
          labelText: isArabic ? 'اسم القائمة الجديد' : 'New List Name',
          prefixIcon: Icons.edit_rounded,
          autofocus: true,
          onSubmitted: (_) => ActionDebouncer.execute(() => _performRename(dialogContext, list, nameController)),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: BeityButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  text: isArabic ? 'إلغاء' : 'Cancel',
                  type: BeityButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: BeityButton(
                  onPressed: () => ActionDebouncer.execute(() => _performRename(dialogContext, list, nameController)),
                  text: isArabic ? 'حفظ' : 'Save',
                  type: BeityButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performRename(BuildContext context, ShoppingList list, TextEditingController controller) async {
    if (controller.text.trim().isNotEmpty) {
      final repository = ref.read(shoppingListRepositoryProvider);
      await repository.updateShoppingList(
        listId: list.id,
        name: controller.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _archiveList(String listId) async {
    final repository = ref.read(shoppingListRepositoryProvider);
    final useCase = ArchiveListUseCase(repository);
    await useCase(listId: listId);
  }

  void _showDeleteConfirmation(BuildContext context, ShoppingList list, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'حذف القائمة' : 'Delete List', textAlign: TextAlign.center),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.error,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        content: Text(
          isArabic 
              ? 'هل أنت متأكد من حذف قائمة "${list.name}"؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: BeityButton(
                  onPressed: () => Navigator.pop(context),
                  text: isArabic ? 'إلغاء' : 'Cancel',
                  type: BeityButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: BeityButton(
                  onPressed: () => ActionDebouncer.execute(() async {
                    final repository = ref.read(shoppingListRepositoryProvider);
                    final useCase = DeleteListUseCase(repository);
                    await useCase(listId: list.id);
                    if (context.mounted) Navigator.pop(context);
                  }),
                  text: isArabic ? 'حذف' : 'Delete',
                  type: BeityButtonType.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
