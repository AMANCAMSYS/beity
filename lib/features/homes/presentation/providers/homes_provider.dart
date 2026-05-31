import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/local_cache_notifier.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:beity/core/services/supabase_service.dart';

import '../../data/repositories/home_repository.dart';
import '../../data/repositories/home_local_data_source.dart';
import '../../data/models/home_model.dart';
import '../../data/models/home_member_model.dart';
import '../../domain/usecases/remove_member_with_balance_check.dart';
import '../../../expenses/presentation/providers/balance_providers.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(SupabaseService.client);
});

final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  return HomeLocalDataSource();
});

final removeMemberWithBalanceCheckProvider =
    Provider<RemoveMemberWithBalanceCheck>((ref) {
  final homeRepo = ref.read(homeRepositoryProvider);
  final settlementRepo = ref.read(settlementRepositoryProvider);
  return RemoveMemberWithBalanceCheck(homeRepo, settlementRepo);
});

// Stream-based Local-First Providers (Requirement 1 & 2)

final userHomesProvider = StreamProvider<List<HomeModel>>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.watchLocalUserHomes();
});

// Synchronous counterparts for instant perceived WhatsApp-like rendering (Phase 1)
final cachedUserHomesProvider = Provider<List<HomeModel>>((ref) {
  final userId = SupabaseService.currentUser?.id ?? 'anonymous';
  
  // 1. Watch the live StreamProvider so this synchronously updates
  final liveHomes = ref.watch(userHomesProvider).valueOrNull;
  if (liveHomes != null) {
    return liveHomes;
  }

  // 2. Synchronous fallback for instant cold start
  try {
    final prefs = AppPreferences.instance;
    final cached = prefs.getString('homes_cache_user:$userId');
    if (cached == null) return [];
    final List<dynamic> list = jsonDecode(cached);
    return list.map((item) => HomeModel.fromJson(item as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

final activeHomeIdProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  final userId = SupabaseService.currentUser?.id ?? 'anonymous';
  return repo.watchActiveHomeId(userId);
});

// Synchronous active home ID and active home providers for instant rendering (Phase 1)
final cachedActiveHomeIdProvider = Provider<String?>((ref) {
  final userId = SupabaseService.currentUser?.id ?? 'anonymous';
  
  // 1. Watch the live StreamProvider so this synchronously updates
  final liveActiveHomeId = ref.watch(activeHomeIdProvider).valueOrNull;
  if (liveActiveHomeId != null) {
    return liveActiveHomeId;
  }

  // 2. Synchronous fallback for instant cold start
  try {
    final prefs = AppPreferences.instance;
    return prefs.getString('active_home_user:$userId');
  } catch (_) {
    return null;
  }
});

final cachedActiveHomeProvider = Provider<HomeModel?>((ref) {
  final homes = ref.watch(cachedUserHomesProvider);
  final activeHomeId = ref.watch(cachedActiveHomeIdProvider);
  if (homes.isEmpty || activeHomeId == null) return null;
  
  try {
    return homes.firstWhere(
      (h) => h.id == activeHomeId,
      orElse: () => homes.first,
    );
  } catch (_) {
    return homes.first;
  }
});

final hasHomesProvider = StreamProvider<bool>((ref) async* {
  final repo = ref.watch(homeRepositoryProvider);
  final localDataSource = ref.watch(homeLocalDataSourceProvider);
  final userId = SupabaseService.currentUser?.id ?? 'anonymous';

  // 1. Initial status check
  final syncCompleted = await localDataSource.isInitialSyncCompleted(userId);
  if (!syncCompleted) {
    yield true; // Pretend we have homes to show a Preparing/Loading spinner (Requirement 1)
  } else {
    final homes = await repo.getCachedUserHomes();
    yield homes.isNotEmpty;
  }

  // 2. Stream updates dynamically from watchLocalUserHomes
  await for (final homes in repo.watchLocalUserHomes()) {
    final completed = await localDataSource.isInitialSyncCompleted(userId);
    if (!completed) {
      yield true;
    } else {
      yield homes.isNotEmpty;
    }
  }
});

final homeMembersProvider =
    StreamProvider.family<List<HomeMemberModel>, String>((ref, homeId) {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.watchLocalHomeMembers(homeId);
});

class HomesNotifier extends StateNotifier<AsyncValue<List<HomeModel>>> {
  final HomeRepository _repo;
  final HomeLocalDataSource _localDataSource;

  HomesNotifier(this._repo, this._localDataSource)
      : super(const AsyncValue.loading()) {
    loadHomes();
  }

  Future<void> loadHomes() async {
    state = const AsyncValue.loading();
    try {
      final homes = await _repo.getUserHomes();
      state = AsyncValue.data(homes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<HomeModel> createHome({
    required String name,
    required String type,
    String? defaultCurrency,
  }) async {
    try {
      final home = await _repo.createHome(
        name: name,
        type: type,
        defaultCurrency: defaultCurrency,
      );

      final user = SupabaseService.currentUser;
      if (user != null) {
        await _localDataSource.setActiveHome(home.id, home.name);
      }
      await loadHomes();

      return home;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> switchHome(String homeId, String homeName) async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      await _localDataSource.setActiveHome(homeId, homeName);
      LocalCacheNotifier.notify('global', 'active_home');
    }
  }

  Future<void> refreshHomes() async {
    await loadHomes();
  }
}

final homesNotifierProvider =
    StateNotifierProvider<HomesNotifier, AsyncValue<List<HomeModel>>>((ref) {
  final repo = ref.read(homeRepositoryProvider);
  final localDataSource = ref.read(homeLocalDataSourceProvider);
  return HomesNotifier(repo, localDataSource);
});
