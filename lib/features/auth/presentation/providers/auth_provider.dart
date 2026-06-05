import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/presentation/providers/realtime_providers.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../notifications/presentation/providers/unread_count_provider.dart';
import '../../../notifications/presentation/providers/notification_preferences_provider.dart';
import '../../../tasks/presentation/providers/task_filter_providers.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/startup_prefetch_provider.dart';
import '../../../../core/services/initial_data_hydration_service.dart';
import '../../../../core/services/sync_coordinator.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../../../core/local_database/local_data_deletion_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(SupabaseService.client);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getCurrentUser();
});

final cachedCurrentUserProvider = Provider<UserModel?>((ref) {
  UserModel? authUser;
  try {
    // Supabase.instance throws an assertion or state error if not initialized (like in widget tests)
    Supabase.instance;
    authUser = ref.watch(authNotifierProvider).value;
  } catch (_) {
    // Fallback if Supabase is not initialized
  }

  if (authUser != null) {
    return authUser;
  }

  final futureUser = ref.watch(currentUserProvider).value;
  if (futureUser != null) {
    return futureUser;
  }

  return null;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.authStateChanges;
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  void _invalidateAuthScopedProviders() {
    _ref.invalidate(activeHomeIdProvider);
    _ref.invalidate(userHomesProvider);
    _ref.invalidate(cachedActiveHomeIdProvider);
    _ref.invalidate(cachedUserHomesProvider);
    _ref.invalidate(hasHomesProvider);
  }

  void _invalidateAllState() {
    resetStartupPrefetchState();
    _ref.invalidate(initialDataHydrationServiceProvider);
    _ref.invalidate(syncCoordinatorProvider);
    _ref.invalidate(realtimeServiceProvider);
    _ref.invalidate(offlineQueueRepositoryProvider);
    _ref.invalidate(queueDataSourceProvider);
    _ref.invalidate(syncQueueLockProvider);
    _ref.invalidate(enqueueActionUseCaseProvider);
    _ref.invalidate(getPendingCountUseCaseProvider);
    _ref.invalidate(getQueueEntriesUseCaseProvider);
    _ref.invalidate(shoppingListRepositoryProvider);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
    _ref.invalidate(notificationPreferencesProvider);
    _ref.invalidate(taskFilterProvider);
    _ref.invalidate(activityFilterProvider);
    _ref.invalidate(categoryNotifierProvider);
    _ref.invalidate(unitNotifierProvider);
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(userHomesProvider);
    _ref.invalidate(cachedUserHomesProvider);
    _ref.invalidate(hasHomesProvider);
    _ref.invalidate(activeHomeIdProvider);
    _ref.invalidate(cachedActiveHomeIdProvider);
    _ref.invalidate(homesNotifierProvider);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? language,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        language: language,
      );
      state = AsyncValue.data(user);
      _invalidateAuthScopedProviders();
    } on EmailConfirmationRequiredException {
      state = const AsyncValue.data(null);
      rethrow;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signIn(email: email, password: password);

      final localDataSource = _ref.read(homeLocalDataSourceProvider);
      await localDataSource.setInitialSyncCompleted(user.id, false);

      state = AsyncValue.data(user);
      _invalidateAuthScopedProviders();
      unawaited(
        NotificationService.ready
            .then((ready) {
              return NotificationService.refreshToken();
            })
            .catchError((_) {
              return NotificationService.refreshToken();
            }),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithGoogle();

      final localDataSource = _ref.read(homeLocalDataSourceProvider);
      await localDataSource.setInitialSyncCompleted(user.id, false);

      state = AsyncValue.data(user);
      _invalidateAuthScopedProviders();
      unawaited(
        NotificationService.ready
            .then((ready) {
              return NotificationService.refreshToken();
            })
            .catchError((_) {
              return NotificationService.refreshToken();
            }),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut({bool deleteLocalData = false}) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();

    // Capture current user ID before Supabase clears it on signOut.
    final userId = SupabaseService.client.auth.currentUser?.id;

    try {
      await NotificationService.removeToken();
    } catch (e, s) {
      await MonitoringService().logError(
        e,
        s,
        reason: 'Failed to remove notification token during signout',
      );
    }

    if (deleteLocalData && userId != null) {
      try {
        await LocalDataDeletionService().deleteLocalUserData(userId);
      } catch (e, s) {
        await MonitoringService().logError(
          e,
          s,
          reason: 'Failed to delete local user data during signout',
        );
      }
    }

    try {
      await _repo.signOut();
    } catch (e, s) {
      await MonitoringService().logError(
        e,
        s,
        reason: 'Supabase signOut failed',
      );
    } finally {
      _invalidateAllState();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? country,
    String? dialect,
    String? language,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
        country: country,
        dialect: dialect,
        language: language,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateAvatar({
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final avatarUrl = await _repo.uploadAvatar(
        bytes: bytes,
        extension: extension,
        contentType: contentType,
      );
      final user = await _repo.updateProfile(avatarUrl: avatarUrl);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      final repo = ref.read(authRepositoryProvider);
      return AuthNotifier(repo, ref);
    });
