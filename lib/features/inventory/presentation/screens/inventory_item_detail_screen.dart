import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import '../providers/inventory_provider.dart';
import '../../domain/usecases/delete_inventory_item_usecase.dart';
import '../../domain/entities/inventory_item.dart';
import '../../data/models/inventory_transaction_model.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';

class InventoryItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String homeId;

  const InventoryItemDetailScreen({
    super.key,
    required this.itemId,
    required this.homeId,
  });

  @override
  ConsumerState<InventoryItemDetailScreen> createState() =>
      _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState
    extends ConsumerState<InventoryItemDetailScreen> {
  List<InventoryTransactionModel> _transactions = [];
  bool _loadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final txns = await repo.getTransactions(inventoryItemId: widget.itemId);
      if (mounted) {
        setState(() {
          _transactions = txns;
          _loadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTransactions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(inventoryItemByIdProvider(widget.itemId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.translate('item_details'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: context.translate('edit'),
            onPressed: () {
              context.push(
                '/inventory/${widget.itemId}/edit',
                extra: {'homeId': widget.homeId},
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: () => _confirmDelete(context),
          ),
          AppSpacing.gapSM,
        ],
      ),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              AppSpacing.gapLG,
              Text(
                context.translate('error_occurred'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              AppSpacing.gapSM,
              Text(
                ErrorFormatter.format(e, context),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              AppSpacing.gapXL,
              SawaButton(
                text: context.translate('retry'),
                width: 160,
                onPressed: () =>
                    ref.invalidate(inventoryItemByIdProvider(widget.itemId)),
              ),
            ],
          ),
        ),
        data: (item) {
          if (item == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    AppSpacing.gapLG,
                    Text(
                      context.translate('item_not_found'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapLG,
                    SawaButton(
                      text: context.translate('go_back'),
                      type: SawaButtonType.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildItemCard(item, context, theme),
              AppSpacing.gapXL,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    AppSpacing.gapMD,
                    Text(
                      context.translate('change_logs'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLG,
              _buildTransactionsList(context, theme),
              AppSpacing.gapXXL,
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemCard(
    InventoryItem item,
    BuildContext context,
    ThemeData theme,
  ) {
    return SawaCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              AppSpacing.gapLG,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.gapXXS,
                    Text(
                      context.translate('primary_product_data'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapXL,
          const Divider(),
          AppSpacing.gapXL,
          _infoRow(
            Icons.numbers_rounded,
            context.translate('current_quantity'),
            _formatQuantity(item.quantity),
            theme,
            valueColor: item.isLowStock
                ? theme.colorScheme.error
                : AppColors.primary,
          ),
          if (item.minQuantity != null)
            _infoRow(
              Icons.warning_amber_rounded,
              context.translate('min_quantity'),
              _formatQuantity(item.minQuantity!),
              theme,
            ),
          if (item.notes != null && item.notes!.isNotEmpty)
            _infoRow(
              Icons.notes_rounded,
              context.translate('additional_notes'),
              item.notes!,
              theme,
            ),
          _infoRow(
            Icons.event_available_rounded,
            context.translate('date_added'),
            _formatDate(context, item.createdAt),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapMD,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapXXS,
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, ThemeData theme) {
    if (_loadingTransactions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return SawaCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            AppSpacing.gapLG,
            Text(
              context.translate('no_logs_found'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => AppSpacing.gapSM,
      itemBuilder: (context, i) {
        final txn = _transactions[i];
        final color = _getTransactionColor(txn.changeReason);
        return SawaCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  _getTransactionIcon(txn.changeReason),
                  color: color,
                  size: 20,
                ),
              ),
              AppSpacing.gapLG,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransactionLabel(context, txn.changeReason),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapXXS,
                    Row(
                      children: [
                        Text(
                          '${_formatQuantity(txn.previousQuantity)} ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        AppSpacing.gapXXS,
                        Icon(
                          Icons.east_rounded,
                          size: 10,
                          color: theme.colorScheme.outline,
                        ),
                        AppSpacing.gapXXS,
                        Text(
                          _formatQuantity(txn.newQuantity),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(context, txn.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatQuantity(double q) {
    if (q == q.roundToDouble() && q < 1000) {
      return q.toInt().toString();
    }
    return q.toStringAsFixed(1);
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final lang = Localizations.localeOf(context).languageCode;
    return DateFormat.yMd(lang).add_jm().format(date);
  }

  IconData _getTransactionIcon(String reason) {
    switch (reason) {
      case 'initial_add':
        return Icons.add_circle_rounded;
      case 'manual_update':
        return Icons.edit_note_rounded;
      case 'shopping_restock':
        return Icons.shopping_bag_rounded;
      case 'zero_removal':
        return Icons.remove_circle_rounded;
      case 'delete':
        return Icons.delete_forever_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _getTransactionColor(String reason) {
    switch (reason) {
      case 'initial_add':
        return AppColors.success;
      case 'manual_update':
        return AppColors.primary;
      case 'shopping_restock':
        return AppColors.info;
      case 'zero_removal':
        return AppColors.warning;
      case 'delete':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionLabel(BuildContext context, String reason) {
    switch (reason) {
      case 'initial_add':
      case 'manual_update':
      case 'shopping_restock':
      case 'zero_removal':
      case 'delete':
        return context.translate(reason);
      default:
        return reason;
    }
  }

  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            AppSpacing.gapMD,
            Text(
              context.translate('delete_product'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(context.translate('delete_product_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.translate('cancel'),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SawaButton(
            width: 100,
            text: context.translate('delete'),
            type: SawaButtonType.secondary,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final useCase = DeleteInventoryItemUseCase(
                  ref.read(inventoryRepositoryProvider),
                );
                await useCase(itemId: widget.itemId, homeId: widget.homeId);
                ref.invalidate(inventoryItemsProvider(widget.homeId));
                if (context.mounted) {
                  SawaSnackBar.success(
                    context,
                    context.translate('inventory_item_deleted_success'),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  SawaSnackBar.error(
                    context,
                    context.translate(
                      'error_delete_item',
                      arguments: {'error': ErrorFormatter.format(e, context)},
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
