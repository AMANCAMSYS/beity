import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/local_database/local_data_deletion_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../../../../core/services/sync_coordinator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../providers/app_settings_provider.dart';
import 'settings_shared_widgets.dart';

class SettingsDataSection extends ConsumerStatefulWidget {
  final AppSettingsState settings;
  final AppLocalizations l10n;

  const SettingsDataSection({
    super.key,
    required this.settings,
    required this.l10n,
  });

  @override
  ConsumerState<SettingsDataSection> createState() =>
      _SettingsDataSectionState();
}

class _SettingsDataSectionState extends ConsumerState<SettingsDataSection> {
  String _cacheSizeStr = '0.00 KB';
  String _databaseSizeStr = '0.00 KB';
  String _lastSyncStr = '-';
  int _pendingMutations = 0;
  String? _statsHomeId;
  bool _isSyncingNow = false;
  bool _isDeletingHomeData = false;
  bool _isDeletingAccountData = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadLocalDataStats();
  }

  Future<void> _loadCacheSize() async {
    try {
      final tempDir = await getApplicationCacheDirectory();
      int totalSize = 0;
      if (await tempDir.exists()) {
        await for (final file in tempDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      final sizeInMb = totalSize / (1024 * 1024);
      final sizeInKb = totalSize / 1024;

      String formattedSize;
      if (sizeInMb >= 1.0) {
        formattedSize = '${sizeInMb.toStringAsFixed(2)} MB';
      } else if (sizeInKb >= 1.0) {
        formattedSize = '${sizeInKb.toStringAsFixed(2)} KB';
      } else {
        formattedSize = '$totalSize B';
      }

      if (mounted) {
        setState(() {
          _cacheSizeStr = formattedSize;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSizeStr = '0.00 KB';
        });
      }
    }
  }

  Future<void> _loadLocalDataStats() async {
    try {
      final service = LocalDataDeletionService();
      final activeHomeId = ref.read(resolvedActiveHomeIdProvider);
      final dbSize = await service.getDatabaseSizeBytes();
      final pendingCount = await service.getPendingMutationsCount(
        homeId: activeHomeId,
      );
      final lastSync = activeHomeId == null
          ? null
          : ref
                .read(syncCoordinatorProvider.notifier)
                .getLastSuccessfulSyncTime(activeHomeId);

      if (mounted) {
        setState(() {
          _statsHomeId = activeHomeId;
          _databaseSizeStr = _formatBytes(dbSize);
          _pendingMutations = pendingCount;
          _lastSyncStr = _formatLastSync(lastSync);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _databaseSizeStr = '0.00 KB';
          _pendingMutations = 0;
          _lastSyncStr = '-';
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(2)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(2)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  String _formatLastSync(DateTime? value) {
    if (value == null || value.millisecondsSinceEpoch <= 0) {
      return widget.l10n.translate('local_never_synced');
    }
    final local = value.toLocal();
    String two(int input) => input.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _handleClearCache() async {
    final l10n = widget.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(l10n.translate('clear_cache_confirm_title')),
        content: Text(l10n.translate('clear_cache_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.translate('clear_cache')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final tempDir = await getApplicationCacheDirectory();
        if (await tempDir.exists()) {
          await for (final file in tempDir.list(
            recursive: true,
            followLinks: false,
          )) {
            try {
              await file.delete(recursive: true);
            } catch (_) {}
          }
        }
      } catch (_) {}

      setState(() {
        _cacheSizeStr = '0.00 KB';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('cache_cleared_success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<bool> _confirmLocalDelete({
    required String titleKey,
    required String descriptionKey,
    required String actionKey,
  }) async {
    final l10n = widget.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            title: Text(l10n.translate(titleKey)),
            content: Text(l10n.translate(descriptionKey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.translate('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Text(l10n.translate(actionKey)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showLocalDataSnack(String key, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.l10n.translate(key)),
        backgroundColor: backgroundColor ?? AppColors.success,
      ),
    );
  }

  Future<void> _handleSyncNow() async {
    final activeHomeId = ref.read(resolvedActiveHomeIdProvider);
    if (activeHomeId == null || activeHomeId.isEmpty) {
      _showLocalDataSnack(
        'no_active_home_for_local_data',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    setState(() => _isSyncingNow = true);
    try {
      await ref
          .read(syncCoordinatorProvider.notifier)
          .syncAll(activeHomeId, force: true, repairMissing: true);
      await _loadLocalDataStats();
      _showLocalDataSnack('local_sync_completed');
    } catch (_) {
      _showLocalDataSnack('sync_error', backgroundColor: AppColors.error);
    } finally {
      if (mounted) setState(() => _isSyncingNow = false);
    }
  }

  Future<void> _handleDeleteHomeLocalData() async {
    final activeHomeId = ref.read(resolvedActiveHomeIdProvider);
    if (activeHomeId == null || activeHomeId.isEmpty) {
      _showLocalDataSnack(
        'no_active_home_for_local_data',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    final confirmed = await _confirmLocalDelete(
      titleKey: 'delete_home_local_data_confirm_title',
      descriptionKey: 'delete_home_local_data_confirm_desc',
      actionKey: 'delete_home_local_data',
    );
    if (!confirmed) return;

    setState(() => _isDeletingHomeData = true);
    try {
      await LocalDataDeletionService().deleteLocalHomeData(activeHomeId);
      LocalCacheNotifier.notify(activeHomeId, 'shopping_lists');
      LocalCacheNotifier.notify('global', 'active_home');
      ref.invalidate(userHomesProvider);
      ref.invalidate(cachedUserHomesProvider);
      ref.invalidate(activeHomeIdProvider);
      ref.invalidate(cachedActiveHomeIdProvider);
      ref.invalidate(homesNotifierProvider);
      ref.invalidate(shoppingListsProvider(activeHomeId));
      await _loadLocalDataStats();
      _showLocalDataSnack('delete_local_data_success');
    } catch (_) {
      _showLocalDataSnack('error_db', backgroundColor: AppColors.error);
    } finally {
      if (mounted) setState(() => _isDeletingHomeData = false);
    }
  }

  Future<void> _handleDeleteAccountLocalData() async {
    final userId = ref.read(cachedCurrentUserProvider)?.id;
    if (userId == null || userId.isEmpty) {
      _showLocalDataSnack(
        'error_auth_generic',
        backgroundColor: AppColors.error,
      );
      return;
    }

    final confirmed = await _confirmLocalDelete(
      titleKey: 'delete_account_local_data_confirm_title',
      descriptionKey: 'delete_account_local_data_confirm_desc',
      actionKey: 'delete_account_local_data',
    );
    if (!confirmed) return;

    setState(() => _isDeletingAccountData = true);
    try {
      await LocalDataDeletionService().deleteLocalUserData(userId);
      LocalCacheNotifier.notify('global', 'active_home');
      ref.invalidate(currentUserProvider);
      ref.invalidate(userHomesProvider);
      ref.invalidate(cachedUserHomesProvider);
      ref.invalidate(activeHomeIdProvider);
      ref.invalidate(cachedActiveHomeIdProvider);
      ref.invalidate(homesNotifierProvider);
      ref.invalidate(shoppingListRepositoryProvider);
      await _loadLocalDataStats();
      _showLocalDataSnack('delete_local_data_success');
    } catch (_) {
      _showLocalDataSnack('error_db', backgroundColor: AppColors.error);
    } finally {
      if (mounted) setState(() => _isDeletingAccountData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final l10n = widget.l10n;
    final activeHomeId = ref.watch(resolvedActiveHomeIdProvider);
    if (_statsHomeId != activeHomeId) {
      _statsHomeId = activeHomeId;
      Future.microtask(_loadLocalDataStats);
    }

    return SettingsSection(
      title: l10n.translate('data_management'),
      children: [
        SettingsSwitchTile(
          icon: Icons.wifi_rounded,
          title: l10n.translate('sync_over_wifi_only'),
          subtitle: l10n.translate('sync_over_wifi_only_subtitle'),
          value: settings.syncOverWifiOnly,
          onChanged: (value) =>
              ref.read(appSettingsProvider.notifier).setSyncOverWifiOnly(value),
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.storage_rounded,
          title: l10n.translate('local_data'),
          subtitle: l10n.translate(
            'local_data_status_subtitle',
            arguments: {
              'size': _databaseSizeStr,
              'pending': _pendingMutations.toString(),
            },
          ),
          onTap: _loadLocalDataStats,
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.history_rounded,
          title: l10n.translate('last_successful_sync'),
          subtitle: _lastSyncStr,
          onTap: _loadLocalDataStats,
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.sync_rounded,
          title: _isSyncingNow
              ? l10n.translate('syncing')
              : l10n.translate('sync_now'),
          subtitle: l10n.translate('sync_now_subtitle'),
          onTap: _handleSyncNow,
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.house_siding_rounded,
          iconColor: AppColors.warning,
          title: _isDeletingHomeData
              ? l10n.translate('deleting_local_data')
              : l10n.translate('delete_home_local_data'),
          subtitle: l10n.translate('delete_home_local_data_subtitle'),
          titleColor: AppColors.warning,
          onTap: _handleDeleteHomeLocalData,
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.person_remove_rounded,
          iconColor: AppColors.error,
          title: _isDeletingAccountData
              ? l10n.translate('deleting_local_data')
              : l10n.translate('delete_account_local_data'),
          subtitle: l10n.translate('delete_account_local_data_subtitle'),
          titleColor: AppColors.error,
          onTap: _handleDeleteAccountLocalData,
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.delete_sweep_rounded,
          title: l10n.translate('clear_cache'),
          subtitle: l10n.translate(
            'clear_cache_subtitle',
            arguments: {'size': _cacheSizeStr},
          ),
          onTap: _handleClearCache,
        ),
      ],
    );
  }
}
