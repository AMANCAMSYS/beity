import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/sync_coordinator.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../homes/presentation/providers/homes_provider.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(SupabaseService.client);
  ref.onDispose(() => service.disposeAll());
  return service;
});

final connectionStateProvider = StreamProvider<ConnectionStateModel>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.connectionState;
});

final offlineQueueFlushProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<ConnectionStateModel>>(connectionStateProvider,
      (previous, next) async {
    final currentState = next.valueOrNull;
    final previousState = previous?.valueOrNull;
    if (currentState != null &&
        currentState.status == ConnectionStatus.connected &&
        previousState?.status != ConnectionStatus.connected) {
      
      final syncUseCase = ref.read(syncQueueUseCaseProvider);
      final localDataSource = ref.read(homeLocalDataSourceProvider);
      final activeHomeId = await localDataSource.getActiveHomeId();
      
      if (activeHomeId != null && activeHomeId.isNotEmpty) {
        // 1. Flush offline outbox queue first
        await syncUseCase.execute(activeHomeId);
        
        // 2. Trigger global background delta sync when connection is restored
        ref.read(syncCoordinatorProvider.notifier).syncAll(activeHomeId, force: true);
      }
    }
  });
});
