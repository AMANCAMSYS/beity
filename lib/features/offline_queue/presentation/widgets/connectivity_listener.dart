import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/device_sync_status.dart';
import '../providers/connectivity_provider.dart';
import '../providers/offline_queue_provider.dart';
import '../../../../core/services/sync_coordinator.dart';

class ConnectivityListener extends ConsumerStatefulWidget {
  final Widget child;
  final String homeId;

  const ConnectivityListener({
    super.key,
    required this.child,
    required this.homeId,
  });

  @override
  ConsumerState<ConnectivityListener> createState() =>
      _ConnectivityListenerState();
}

class _ConnectivityListenerState extends ConsumerState<ConnectivityListener> {
  DeviceSyncStatus? _previousStatus;

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    connectivityAsync.whenData((status) {
      if (_previousStatus == DeviceSyncStatus.offline && status.isOnline) {
        // Transitioned from offline to online - trigger sync
        _triggerSync();
      }
      _previousStatus = status;
    });

    return widget.child;
  }

  Future<void> _triggerSync() async {
    final syncUseCase = ref.read(syncQueueUseCaseProvider);

    // 1. Sync home-scoped entries
    final result = await syncUseCase.execute(widget.homeId);

    // 2. Sync user-scoped and global-scoped entries
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId != null) {
      await syncUseCase.executeUserScope(userId);
    }

    if (result.hasResults && mounted) {
      String message;
      Color backgroundColor;

      if (result.allSucceeded) {
        message = context.translate('sync_success');
        backgroundColor = AppColors.success;
      } else {
        message = context.translate('sync_partial_failed');
        backgroundColor = AppColors.error;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh queue entries
      ref.invalidate(queueEntriesProvider(widget.homeId));
      ref.invalidate(pendingCountProvider(widget.homeId));

      // Trigger a Delta Sync on all tables to pull updates for the home
      ref
          .read(syncCoordinatorProvider.notifier)
          .syncAll(widget.homeId, force: true);
    }
  }
}
