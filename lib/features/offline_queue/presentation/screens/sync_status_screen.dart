import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:beity/core/localization/app_localizations.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../features/settings/presentation/providers/app_settings_provider.dart';
import '../../../../features/homes/presentation/providers/homes_provider.dart';
import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../providers/offline_queue_provider.dart';
import '../providers/sync_status_provider.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _isSyncingInProgress = false;

  String _getActionDisplayName(ActionType type, bool isArabic) {
    if (isArabic) {
      return switch (type) {
        ActionType.addItem => 'إضافة عنصر',
        ActionType.updateItem => 'تعديل عنصر',
        ActionType.deleteItem => 'حذف عنصر',
        ActionType.markPurchased => 'تحديد كمشترى',
        ActionType.updateQuantity => 'تعديل الكمية',
      };
    } else {
      return type.displayName;
    }
  }

  String _getEntityDisplayName(EntityType type, bool isArabic) {
    if (isArabic) {
      return switch (type) {
        EntityType.shoppingItem => 'عنصر تسوق',
        EntityType.shoppingList => 'قائمة تسوق',
      };
    } else {
      return type.displayName;
    }
  }

  String _getPayloadSummary(QueueEntry entry) {
    final payload = entry.payload;
    if (payload.containsKey('name')) {
      return payload['name'] as String;
    }
    if (payload.containsKey('title')) {
      return payload['title'] as String;
    }
    if (payload.containsKey('item_name')) {
      return payload['item_name'] as String;
    }
    return 'ID: ${entry.entityId}';
  }

  Future<void> _syncAll(String homeId, bool isArabic) async {
    setState(() => _isSyncingInProgress = true);
    try {
      final syncUseCase = ref.read(syncQueueUseCaseProvider);
      await syncUseCase.execute(homeId);
      
      // Refresh state
      ref.invalidate(queueEntriesProvider(homeId));
      ref.invalidate(syncStatusProvider(homeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تمت مزامنة البيانات بنجاح' : 'Data synced successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'فشلت المزامنة: ${e.toString()}'
                  : 'Sync failed: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingInProgress = false);
      }
    }
  }

  Future<void> _retryEntry(String homeId, QueueEntry entry, bool isArabic) async {
    final entryId = entry.id;
    if (entryId == null) return;

    try {
      await ref.read(offlineQueueRepositoryProvider).updateEntryStatus(
            entryId: entryId,
            status: SyncStatus.pending,
          );
      
      // Execute sync
      final syncUseCase = ref.read(syncQueueUseCaseProvider);
      await syncUseCase.execute(homeId);

      // Refresh
      ref.invalidate(queueEntriesProvider(homeId));
      ref.invalidate(syncStatusProvider(homeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تمت إعادة محاولة المزامنة' : 'Sync retry triggered',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'فشلت محاولة إعادة المزامنة: ${e.toString()}'
                  : 'Failed to retry sync: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(String homeId, QueueEntry entry, bool isArabic) async {
    final entryId = entry.id;
    if (entryId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'حذف العنصر؟' : 'Delete Action?'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف هذا الإجراء من قائمة المزامنة؟ قد يؤدي هذا لتراجع التعديلات التي قمت بها.'
              : 'Are you sure you want to delete this action? This will undo your local modification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(offlineQueueRepositoryProvider).deleteEntry(entryId);
        
        ref.invalidate(queueEntriesProvider(homeId));
        ref.invalidate(syncStatusProvider(homeId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'تم حذف العنصر بنجاح' : 'Action deleted successfully',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = ref.watch(appSettingsProvider).locale.languageCode == 'ar';
    final activeHomeId = ref.watch(cachedActiveHomeIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'حالة المزامنة' : 'Sync Status'),
        centerTitle: true,
      ),
      body: activeHomeId == null || activeHomeId.isEmpty
          ? _buildNoHomeState(theme, isArabic)
          : ref.watch(syncStatusProvider(activeHomeId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    isArabic
                        ? '${context.translate('error_loading_data')}: $err'
                        : 'Error loading sync details: $err',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (statusState) {
                  return ref.watch(queueEntriesProvider(activeHomeId)).when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Text(
                            isArabic
                                ? 'خطأ في جلب عناصر المزامنة: $err'
                                : 'Error fetching sync entries: $err',
                          ),
                        ),
                        data: (entries) {
                          return _buildMainLayout(
                            context,
                            theme,
                            activeHomeId,
                            statusState,
                            entries,
                            isArabic,
                          );
                        },
                      );
                },
              ),
    );
  }

  Widget _buildNoHomeState(ThemeData theme, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_rounded,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            AppSpacing.gapLG,
            Text(
              isArabic
                  ? 'لم يتم تحديد منزل نشط بعد'
                  : 'No active home selected',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapSM,
            Text(
              isArabic
                  ? context.translate('select_home_for_sync')
                  : 'Please go to Manage Homes and select an active home to sync.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapLG,
            ElevatedButton.icon(
              onPressed: () => context.push('/homes'),
              icon: const Icon(Icons.home),
              label: Text(isArabic ? 'إدارة المنازل' : 'Manage Homes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLayout(
    BuildContext context,
    ThemeData theme,
    String homeId,
    SyncStatusState statusState,
    List<QueueEntry> entries,
    bool isArabic,
  ) {
    final isDeviceOffline = statusState.isOffline;
    final totalActions = entries.length;
    final failedCount = entries.where((e) => e.isFailed).length;
    final pendingCount = entries.where((e) => e.isPending || e.isSyncing).length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(queueEntriesProvider(homeId));
        ref.invalidate(syncStatusProvider(homeId));
        await ref.read(queueEntriesProvider(homeId).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Connection status card
          _buildConnectionCard(theme, isDeviceOffline, isArabic),
          AppSpacing.gapLG,

          // 2. Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  theme,
                  isArabic ? 'بانتظار المزامنة' : 'Pending',
                  pendingCount.toString(),
                  AppColors.info,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: _buildStatBox(
                  theme,
                  isArabic ? 'عمليات فشلت' : 'Failed',
                  failedCount.toString(),
                  failedCount > 0 ? AppColors.error : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          AppSpacing.gapLG,

          // 3. Action Section
          if (totalActions > 0)
            ElevatedButton.icon(
              onPressed: (isDeviceOffline || _isSyncingInProgress)
                  ? null
                  : () => _syncAll(homeId, isArabic),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: theme.colorScheme.outlineVariant,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              icon: _isSyncingInProgress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(
                _isSyncingInProgress
                    ? (isArabic ? 'جاري المزامنة...' : 'Syncing...')
                    : (isArabic ? 'المزامنة الآن' : 'Sync Now'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          AppSpacing.gapXL,

          // 4. Log Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'تفاصيل السجلات المعلقة' : 'Pending Action Logs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalActions ${isArabic ? 'إجراء' : 'actions'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.gapMD,

          // 5. Entries List
          if (entries.isEmpty)
            _buildEmptyLogsState(theme, isArabic)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => AppSpacing.gapSM,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _buildEntryCard(context, theme, homeId, entry, isArabic);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    ThemeData theme,
    bool isOffline,
    bool isArabic,
  ) {
    final statusColor = isOffline ? AppColors.warning : AppColors.success;
    final bgGradient = LinearGradient(
      colors: isOffline
          ? [
              AppColors.warning.withValues(alpha: 0.15),
              AppColors.warning.withValues(alpha: 0.05),
            ]
          : [
              theme.colorScheme.primary.withValues(alpha: 0.15),
              theme.colorScheme.primary.withValues(alpha: 0.03),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: statusColor,
              size: 28,
            ),
          ),
          AppSpacing.gapLG,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOffline
                      ? (isArabic ? 'وضع غير متصل بالإنترنت' : 'Offline Mode')
                      : (isArabic ? 'متصل بالإنترنت' : 'Online Status'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOffline
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOffline
                      ? (isArabic
                          ? 'سيتم الاحتفاظ بالتغييرات ومزامنتها تلقائياً عند عودة الاتصال'
                          : 'Local changes will be preserved and synced when you reconnect')
                      : (isArabic
                          ? 'تطبيقك متصل بالخادم وجاهز لإجراء العمليات فوراً'
                          : 'Your app is fully connected and ready for instant sync'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLogsState(ThemeData theme, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.cloud_done_rounded,
              size: 52,
              color: AppColors.success.withValues(alpha: 0.7),
            ),
            AppSpacing.gapMD,
            Text(
              isArabic
                  ? 'كل البيانات متزامنة تماماً!'
                  : 'All data is fully synced!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapXS,
            Text(
              isArabic
                  ? 'لا توجد إجراءات معلقة في قائمة الانتظار الحالية.'
                  : 'There are no pending actions in your local queue.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    ThemeData theme,
    String homeId,
    QueueEntry entry,
    bool isArabic,
  ) {
    final isFailed = entry.isFailed;
    final isSyncing = entry.isSyncing;
    final typeColor = isFailed
        ? AppColors.error
        : isSyncing
            ? AppColors.info
            : theme.colorScheme.primary;

    final actionText = _getActionDisplayName(entry.actionType, isArabic);
    final entityText = _getEntityDisplayName(entry.entityType, isArabic);
    final summaryText = _getPayloadSummary(entry);

    final timeFormatted = timeago.format(
      entry.createdAt,
      locale: isArabic ? 'ar' : 'en',
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isFailed
              ? AppColors.error.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
          width: isFailed ? 1.2 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              isFailed
                  ? Icons.sms_failed_rounded
                  : isSyncing
                      ? Icons.sync_rounded
                      : Icons.cloud_queue_rounded,
              color: typeColor,
              size: 22,
            ),
          ),
          title: Text(
            '$actionText ($entityText)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isFailed ? AppColors.error : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text(
                summaryText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeFormatted,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (entry.retryCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        isArabic
                            ? 'محاولات: ${entry.retryCount}'
                            : 'Retries: ${entry.retryCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            if (isFailed && entry.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'رسالة الخطأ:' : 'Error Message:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteEntry(homeId, entry, isArabic),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(isArabic ? 'إلغاء الإجراء' : 'Cancel Action'),
                ),
                if (isFailed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () => _retryEntry(homeId, entry, isArabic),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(isArabic ? 'إعادة المحاولة' : 'Retry Now'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
