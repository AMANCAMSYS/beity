import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/core/monitoring/monitoring_service.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/sync_coordinator.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:sawa/features/offline_queue/presentation/providers/offline_queue_provider.dart';
import 'package:sawa/core/services/notification_service.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  String _appVersion = '...';
  bool _notificationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _checkNotificationPermission();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final ready = await NotificationService.ready;
      if (mounted) {
        setState(() {
          _notificationPermissionGranted = ready;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notificationPermissionGranted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitoring = MonitoringService();
    final activeHomeId = ref.watch(cachedActiveHomeIdProvider);
    final syncState = ref.watch(syncCoordinatorProvider);

    final pendingCountAsync = activeHomeId != null
        ? ref.watch(pendingCountProvider(activeHomeId))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('diagnostics')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: context.translate('app_info'),
              icon: Icons.info_outline_rounded,
              children: [
                _buildInfoRow(
                  context,
                  label: context.translate('app_version'),
                  value: _appVersion,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: context.translate('sync_status'),
              icon: Icons.sync_rounded,
              children: [
                _buildInfoRow(
                  context,
                  label: context.translate('current_status'),
                  value: _syncStatusText(syncState.status),
                  valueColor: _syncStatusColor(theme, syncState.status),
                ),
                if (syncState.domainErrors.isNotEmpty) ...[
                  const Divider(),
                  _buildInfoRow(
                    context,
                    label: context.translate('domain_errors'),
                    value: syncState.domainErrors.keys.join(', '),
                    valueColor: theme.colorScheme.error,
                  ),
                ],
                if (syncState.lastSyncTimes.isNotEmpty) ...[
                  const Divider(),
                  _buildInfoRow(
                    context,
                    label: context.translate('last_successful_sync'),
                    value: _formatLastSyncTime(syncState, activeHomeId),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: context.translate('offline_queue'),
              icon: Icons.queue_rounded,
              children: [
                _buildInfoRow(
                  context,
                  label: context.translate('pending_operations'),
                  value:
                      pendingCountAsync?.when(
                        data: (count) => count.toString(),
                        loading: () => '...',
                        error: (_, _) => '?',
                      ) ??
                      'N/A',
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  label: context.translate('last_sync_error'),
                  value:
                      monitoring.lastSyncErrorId ?? context.translate('none'),
                  valueColor: monitoring.lastSyncErrorId != null
                      ? theme.colorScheme.error
                      : null,
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  label: context.translate('retry_count'),
                  value: monitoring.retryCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: context.translate('notifications'),
              icon: Icons.notifications_outlined,
              children: [
                _buildInfoRow(
                  context,
                  label: context.translate('permission_status'),
                  value: _notificationPermissionGranted
                      ? context.translate('granted')
                      : context.translate('denied'),
                  valueColor: _notificationPermissionGranted
                      ? Colors.green
                      : theme.colorScheme.error,
                ),
                if (NotificationService.fcmToken != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    context,
                    label: 'FCM Token',
                    value: context.translate('available'),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: context.translate('performance_checkpoints'),
              icon: Icons.speed_rounded,
              children: [
                _buildInfoRow(
                  context,
                  label: context.translate('app_start'),
                  value: _formatTimestamp(monitoring.appStartTime),
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  label: context.translate('home_first_render'),
                  value: _formatTimestamp(monitoring.homeFirstRenderTime),
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  label: context.translate('shopping_list_first_render'),
                  value: _formatTimestamp(
                    monitoring.shoppingListFirstRenderTime,
                  ),
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  label: context.translate('add_item_local_commit'),
                  value: _formatTimestamp(monitoring.addItemLocalCommitTime),
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  label: context.translate('sync_completion'),
                  value: _formatTimestamp(monitoring.syncCompletionTime),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: context.translate('recent_logs'),
              icon: Icons.bug_report_outlined,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: monitoring
                          .getRecentLogs()
                          .reversed
                          .take(20)
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _sanitizeDiagnosticLog(log),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _syncStatusText(SyncStatus status) {
    return switch (status) {
      SyncStatus.idle => context.translate('sync_status_pending'),
      SyncStatus.syncing => context.translate('sync_status_syncing'),
      SyncStatus.success => context.translate('sync_status_online'),
      SyncStatus.partiallySynced => context.translate('partially_synced'),
      SyncStatus.error => context.translate('sync_status_failed'),
    };
  }

  Color? _syncStatusColor(ThemeData theme, SyncStatus status) {
    return switch (status) {
      SyncStatus.idle => null,
      SyncStatus.syncing => theme.colorScheme.primary,
      SyncStatus.success => Colors.green,
      SyncStatus.partiallySynced => Colors.orange,
      SyncStatus.error => theme.colorScheme.error,
    };
  }

  String _formatLastSyncTime(SyncState syncState, String? activeHomeId) {
    if (activeHomeId == null) return 'N/A';

    final coordinator = MonitoringService();
    final syncCompletion = coordinator.syncCompletionTime;
    if (syncCompletion != null) {
      return '${syncCompletion.hour.toString().padLeft(2, '0')}:${syncCompletion.minute.toString().padLeft(2, '0')}:${syncCompletion.second.toString().padLeft(2, '0')}';
    }

    if (syncState.lastSyncTimes.isNotEmpty) {
      final latest = syncState.lastSyncTimes.values.reduce(
        (a, b) => a.isAfter(b) ? a : b,
      );
      return '${latest.hour.toString().padLeft(2, '0')}:${latest.minute.toString().padLeft(2, '0')}:${latest.second.toString().padLeft(2, '0')}';
    }

    return context.translate('local_never_synced');
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '-';
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  String _sanitizeDiagnosticLog(String log) {
    var sanitized = log
        .replaceAll(
          RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
          '[email]',
        )
        .replaceAll(
          RegExp(
            r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
          ),
          '[id]',
        )
        .replaceAll(
          RegExp(r'\b[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
          '[token]',
        );

    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9:_-]{32,}\b'),
      (match) =>
          _looksSensitive(match.group(0)!) ? '[secret]' : match.group(0)!,
    );
    return sanitized;
  }

  bool _looksSensitive(String value) {
    final hasLetters = RegExp('[A-Za-z]').hasMatch(value);
    final hasNumbers = RegExp(r'\d').hasMatch(value);
    return hasLetters && hasNumbers;
  }
}
