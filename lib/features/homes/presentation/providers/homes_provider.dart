import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/home_repository.dart';
import '../../data/repositories/home_local_data_source.dart';
import '../../data/models/home_model.dart';
import '../../data/models/home_member_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(Supabase.instance.client);
});

final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  return HomeLocalDataSource();
});

final userHomesProvider = FutureProvider<List<HomeModel>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getUserHomes();
});

final activeHomeIdProvider = FutureProvider<String?>((ref) async {
  final localDataSource = ref.read(homeLocalDataSourceProvider);
  final activeId = await localDataSource.getActiveHomeId();
  if (activeId != null && activeId.isNotEmpty) return activeId;

  final repo = ref.read(homeRepositoryProvider);
  final homes = await repo.getUserHomes();
  if (homes.isNotEmpty) {
    await localDataSource.setActiveHome(homes.first.id, homes.first.name);
    return homes.first.id;
  }
  return null;
});

final hasHomesProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.hasHomes();
});

final homeMembersProvider =
    FutureProvider.family<List<HomeMemberModel>, String>((ref, homeId) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getHomeMembers(homeId);
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

      await _localDataSource.setActiveHome(home.id, home.name);
      await loadHomes();

      return home;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> switchHome(String homeId, String homeName) async {
    await _localDataSource.setActiveHome(homeId, homeName);
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
