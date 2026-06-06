import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/app/router/feature_route_paths.dart';
import 'package:sawa/core/config/feature_flags.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:sawa/core/monitoring/monitoring_service.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import 'package:sawa/core/utils/action_debouncer.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_items_provider.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/shopping_lists/domain/usecases/complete_list_usecase.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/categories/presentation/providers/units_provider.dart';
import 'package:sawa/features/inventory/domain/usecases/add_purchased_to_inventory_usecase.dart';
import 'package:sawa/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:sawa/features/beta/data/beta_config.dart';
import 'package:sawa/features/beta/presentation/satisfaction_survey_dialog.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_session_provider.dart';
import 'package:sawa/features/shopping_mode/data/services/shopping_mode_session_recovery_service.dart';

class ShoppingModeExitHandler {
  final WidgetRef ref;
  final BuildContext context;
  final String listId;
  final String homeId;
  final ({String listId, String homeId}) itemsProviderParams;

  ShoppingModeExitHandler({
    required this.ref,
    required this.context,
    required this.listId,
    required this.homeId,
    required this.itemsProviderParams,
  });

  void showExitConfirmation() {
    final purchasedCount = ref.read(
      shoppingModePurchasedCountForHomeProvider(itemsProviderParams),
    );
    final totalCount = ref.read(
      shoppingModeTotalCountForHomeProvider(itemsProviderParams),
    );
    final unpurchasedCount = totalCount - purchasedCount;

    if (unpurchasedCount > 0) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.translate('exit_shopping_mode_question')),
          content: Text(
            dialogContext.translate(
              'exit_shopping_mode_warning',
              arguments: {'count': unpurchasedCount.toString()},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.translate('cancel')),
            ),
            FilledButton(
              onPressed: () => ActionDebouncer.execute(() async {
                Navigator.pop(dialogContext);
                if (FeatureFlags.enableInventory && purchasedCount > 0) {
                  await autoTransferToInventory();
                } else {
                  await exitShoppingMode();
                }
              }),
              child: Text(dialogContext.translate('exit')),
            ),
          ],
        ),
      );
    } else {
      if (FeatureFlags.enableInventory && purchasedCount > 0) {
        autoTransferToInventory();
      } else {
        exitShoppingMode();
      }
    }
  }

  Future<void> exitShoppingMode({
    bool completeList = true,
    bool endSession = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    unawaited(MonitoringService().breadcrumbShoppingModeEnd(listId));

    if (endSession) {
      try {
        await endActiveSession();
      } catch (e) {
        await MonitoringService().log('Failed to end shopping session: $e');
        if (context.mounted) {
          SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        }
        return;
      }
    }

    if (completeList) {
      try {
        final repository = ref.read(
          shoppingListRepositoryForHomeProvider(homeId),
        );
        await CompleteListUseCase(repository).call(listId: listId);
        if (!context.mounted) return;
        ref.invalidate(shoppingListsProvider(homeId));
      } catch (e) {
        await MonitoringService().log('Failed to complete list: $e');
        if (context.mounted) {
          SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        }
        return;
      }
    }

    ref.read(shoppingModeProvider.notifier).deactivate();

    final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
    if (hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    stopwatch.stop();
    await MonitoringService().log(
      'Shopping mode exit took ${stopwatch.elapsedMilliseconds}ms',
    );
    if (!context.mounted) return;

    if (context.canPop()) {
      context.pop();
    }

    if (BetaConfig.isBeta && context.mounted) {
      await SatisfactionSurveyDialog.showIfNeeded(context);
    }
  }

  Future<void> endActiveSession() async {
    final shoppingMode = ref.read(shoppingModeProvider);
    if (shoppingMode.sessionId == null) return;

    final purchasedCount = ref.read(
      shoppingModePurchasedCountForHomeProvider(itemsProviderParams),
    );
    final useCase = ref.read(endShoppingSessionUseCaseProvider);
    await useCase.call(
      sessionId: shoppingMode.sessionId!,
      itemsPurchasedCount: purchasedCount,
    );
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser != null) {
      await ref
          .read(shoppingModeSessionRecoveryServiceProvider)
          .clearActiveSession(currentUser.id);
    }
  }

  Future<void> autoTransferToInventory() async {
    List<ShoppingItemModel> purchasedItems;
    try {
      final items = await ref.read(
        shoppingItemsForHomeProvider(itemsProviderParams).future,
      );
      purchasedItems = items
          .where((i) => i.isPurchased || i.purchasedQuantity > 0)
          .toList();
    } catch (e) {
      if (context.mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
      return;
    }

    if (purchasedItems.isEmpty) {
      await exitShoppingMode();
      return;
    }

    if (!context.mounted) return;
    _showInventoryConfirmDialog(purchasedItems);
  }

  void _showInventoryConfirmDialog(List<ShoppingItemModel> purchasedItems) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.translate('add_to_inventory_question')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogContext.translate(
                'add_to_inventory_msg',
                arguments: {'count': purchasedItems.length.toString()},
              ),
            ),
            const SizedBox(height: 12),
            ...purchasedItems
                .take(5)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final unitsAsync = ref.watch(unitsProvider(null));
                              final units = unitsAsync.value ?? [];
                              final unit = units
                                  .where((u) => u.id == item.unitId)
                                  .firstOrNull;
                              final unitName = unit?.symbol;

                              final qtyToTransfer = item.purchasedQuantity > 0
                                  ? item.purchasedQuantity
                                  : item.quantity;
                              final qty =
                                  qtyToTransfer == qtyToTransfer.roundToDouble()
                                  ? qtyToTransfer.toInt().toString()
                                  : qtyToTransfer.toStringAsFixed(1);

                              final displayQty =
                                  unitName != null && unitName.isNotEmpty
                                  ? '$qty $unitName'
                                  : qty;

                              return Text('${item.name} ($displayQty)');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (purchasedItems.length > 5)
              Text(
                dialogContext.translate(
                  'and_more_items',
                  arguments: {'count': (purchasedItems.length - 5).toString()},
                ),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ActionDebouncer.execute(() async {
              Navigator.pop(dialogContext);
              await exitShoppingMode();
            }),
            child: Text(dialogContext.translate('exit')),
          ),
          FilledButton.icon(
            onPressed: () => ActionDebouncer.execute(() async {
              Navigator.pop(dialogContext);
              await _transferToInventory(purchasedItems);
            }),
            icon: const Icon(Icons.inventory_2),
            label: Text(dialogContext.translate('add_to_inventory')),
          ),
        ],
      ),
    );
  }

  Future<void> _transferToInventory(
    List<ShoppingItemModel> purchasedItems,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final useCase = ref.read(addPurchasedToInventoryUseCaseProvider);
      int successCount = 0;

      try {
        final inputs = purchasedItems
            .map(
              (item) => PurchasedItemInput(
                name: item.name,
                quantity: item.purchasedQuantity > 0
                    ? item.purchasedQuantity
                    : item.quantity,
                unitId: item.unitId,
                categoryId: item.categoryId,
              ),
            )
            .toList();

        await endActiveSession();
        await useCase.callBatch(listId: listId, homeId: homeId, items: inputs);
        successCount = purchasedItems.length;
      } catch (e) {
        await MonitoringService().log(
          'Failed to transfer batch of items to inventory: $e',
        );
        if (context.mounted) {
          Navigator.pop(context);
          SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        }
        return;
      }

      stopwatch.stop();
      await MonitoringService().log(
        'Inventory transfer: $successCount/${purchasedItems.length} items in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (!context.mounted) return;

      if (context.mounted) {
        Navigator.pop(context);
      }

      ref.invalidate(shoppingListsProvider(homeId));
      await exitShoppingMode(completeList: false, endSession: false);

      if (successCount > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.translate(
                        'added_to_inventory_success',
                        arguments: {'count': successCount.toString()},
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: context.translate('view_inventory'),
                textColor: Colors.white,
                onPressed: () => context.push(FeatureRoutePaths.inventory),
              ),
            ),
          );
        }
      }
    } finally {
      // no-op
    }
  }
}
