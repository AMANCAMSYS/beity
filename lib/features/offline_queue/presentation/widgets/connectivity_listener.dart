import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/device_sync_status.dart';
import '../providers/connectivity_provider.dart';
import '../providers/offline_queue_provider.dart';
import '../../domain/usecases/sync_queue_usecase.dart';
import '../../data/datasources/queue_action_executor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      if (_previousStatus == DeviceSyncStatus.offline &&
          status.isOnline) {
        // Transitioned from offline to online - trigger sync
        _triggerSync();
      }
      _previousStatus = status;
    });

    return widget.child;
  }

  Future<void> _triggerSync() async {
    final repository = ref.read(offlineQueueRepositoryProvider);
    final connectivityRepository = ref.read(connectivityRepositoryProvider);
    final client = Supabase.instance.client;
    final executor = QueueActionExecutor(client);

    final syncUseCase = SyncQueueUseCase(
      queueRepository: repository,
      connectivityRepository: connectivityRepository,
      executeAction: (entry) => executor.execute(entry),
    );

    final result = await syncUseCase.execute(widget.homeId);

    if (result.hasResults && mounted) {
      String message;
      Color backgroundColor;

      if (result.allSucceeded) {
        message = 'تمت مزامنة ${result.successCount} عنصر بنجاح';
        backgroundColor = Colors.green;
      } else if (result.failedCount > 0) {
        message = 'فشلت مزامنة ${result.failedCount} عنصر';
        backgroundColor = Colors.red;
      } else {
        message = 'تمت المزامنة';
        backgroundColor = Colors.blue;
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
    }
  }
}
