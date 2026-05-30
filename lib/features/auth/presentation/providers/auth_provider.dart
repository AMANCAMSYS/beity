import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';
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
import '../../../../core/monitoring/monitoring_service.dart';

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
    authUser = ref.watch(authNotifierProvider).valueOrNull;
  } catch (_) {
    // Fallback if Supabase is not initialized
  }
  
  if (authUser != null) {
    return authUser;
  }
  
  final futureUser = ref.watch(currentUserProvider).valueOrNull;
  if (futureUser != null) {
    return futureUser;
  }

  try {
    final userId = SupabaseService.currentUser?.id;
    if (userId != null) {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString('${userId}_cached_profile');
      if (cached != null) {
        return UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    }
  } catch (_) {}
  
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

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signIn(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      // 0. Capture current user ID BEFORE signing out (Supabase clears it on signOut)
      final userId = SupabaseService.client.auth.currentUser?.id;

      // 1. Remove device token BEFORE signing out from Supabase (requires auth to delete)
      try {
        await NotificationService.removeToken();
      } catch (e, s) {
        // Just log and continue, don't let token removal failure block sign out
        await MonitoringService().logError(e, s, reason: 'Failed to remove notification token during signout');
      }

      // 2. Clear offline queue for the captured user
      try {
        if (userId != null) {
          final queueDataSource = _ref.read(sharedPreferencesQueueDataSourceProvider);
          await queueDataSource.clearQueueForUser(userId);
        }
      } catch (e, s) {
        await MonitoringService().logError(e, s, reason: 'Failed to clear offline queue during signout');
      }

      // 3. Clear local storage data for the captured user
      try {
        if (userId != null) {
          final localDataSource = _ref.read(homeLocalDataSourceProvider);
          await localDataSource.clearAllUserDataForUser(userId);
        }
      } catch (e, s) {
        await MonitoringService().logError(e, s, reason: 'Failed to clear local user data during signout');
      }

      // 4. Sign out from Supabase
      await _repo.signOut();

      // 4. Invalidate realtime service (triggers dispose of all channels)
      _ref.invalidate(realtimeServiceProvider);

      // 5. Invalidate offline queue providers
      _ref.invalidate(offlineQueueRepositoryProvider);
      _ref.invalidate(sharedPreferencesQueueDataSourceProvider);
      _ref.invalidate(enqueueActionUseCaseProvider);
      _ref.invalidate(getPendingCountUseCaseProvider);
      _ref.invalidate(getQueueEntriesUseCaseProvider);

      // 6. Invalidate shopping data providers
      _ref.invalidate(shoppingListRepositoryProvider);

      // 7. Invalidate notification providers
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadCountProvider);
      _ref.invalidate(notificationPreferencesProvider);

      // 8. Invalidate task providers
      _ref.invalidate(taskFilterProvider);

      // 9. Invalidate activity log providers
      _ref.invalidate(activityFilterProvider);

      // 10. Invalidate category/unit providers
      _ref.invalidate(categoryNotifierProvider);
      _ref.invalidate(unitNotifierProvider);

      // 11. Invalidate home and user providers
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(userHomesProvider);
      _ref.invalidate(hasHomesProvider);
      _ref.invalidate(activeHomeIdProvider);
      _ref.invalidate(homesNotifierProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      // Even if Supabase signOut fails, clear local state to prevent data leakage
      _ref.invalidate(realtimeServiceProvider);
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(userHomesProvider);
      _ref.invalidate(hasHomesProvider);
      _ref.invalidate(activeHomeIdProvider);
      _ref.invalidate(homesNotifierProvider);
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadCountProvider);
      _ref.invalidate(notificationPreferencesProvider);
      _ref.invalidate(taskFilterProvider);
      _ref.invalidate(activityFilterProvider);

      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
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
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});
