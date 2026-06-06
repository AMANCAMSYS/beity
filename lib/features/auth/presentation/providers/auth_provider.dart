import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../../../core/local_database/local_data_deletion_service.dart';
import '../../../../core/providers/provider_lifecycle_manager.dart';

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

class AuthNotifier extends AsyncNotifier<UserModel?> {
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  FutureOr<UserModel?> build() {
    // T028: Listen to Supabase auth state changes
    _authStateSubscription = SupabaseService.client.auth.onAuthStateChange
        .listen(
          (authState) {
            _handleAuthStateChange(authState);
          },
          onError: (error) {
            // Auth state stream error - don't crash, just log
            MonitoringService().logError(
              error,
              StackTrace.current,
              reason: 'Auth state stream error',
            );
          },
        );

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _authStateSubscription?.cancel();
      _authStateSubscription = null;
    });

    return null;
  }

  /// T029: Handle auth state changes for expired/revoked/external sessions
  void _handleAuthStateChange(AuthState authState) {
    final event = authState.event;

    switch (event) {
      case AuthChangeEvent.signedIn:
        // Refresh user data on sign in
        _refreshCurrentUser();
        break;
      case AuthChangeEvent.signedOut:
        // T029: Session expired, revoked, or externally changed
        _handleSessionEnded();
        break;
      case AuthChangeEvent.tokenRefreshed:
        // Token refreshed - update user data if needed
        _refreshCurrentUser();
        break;
      case AuthChangeEvent.userUpdated:
        // User data updated externally
        _refreshCurrentUser();
        break;
      default:
        break;
    }
  }

  /// Handle session ended (expired, revoked, or external logout)
  void _handleSessionEnded() {
    // Only clean up if we currently have a user
    if (state.value != null) {
      _invalidateAllState();
      state = const AsyncValue.data(null);
    }
  }

  /// Refresh current user data from Supabase
  Future<void> _refreshCurrentUser() async {
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = AsyncValue.data(user);
      }
    } catch (e) {
      // Don't crash on refresh failure
      MonitoringService().logError(
        e,
        StackTrace.current,
        reason: 'Failed to refresh user on auth state change',
      );
    }
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  void _invalidateAuthScopedProviders() {
    ref.read(providerLifecycleManagerProvider).invalidateOnHomeSwitch();
  }

  void _invalidateAllState() {
    ref.read(providerLifecycleManagerProvider).invalidateOnLogout();
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
      unawaited(MonitoringService().breadcrumbAuthSignUp(userId: user.id));
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

      final localDataSource = ref.read(homeLocalDataSourceProvider);
      await localDataSource.setInitialSyncCompleted(user.id, false);

      state = AsyncValue.data(user);
      _invalidateAuthScopedProviders();
      unawaited(MonitoringService().breadcrumbAuthSignIn(userId: user.id));
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

      final localDataSource = ref.read(homeLocalDataSourceProvider);
      await localDataSource.setInitialSyncCompleted(user.id, false);

      state = AsyncValue.data(user);
      _invalidateAuthScopedProviders();
      unawaited(MonitoringService().breadcrumbAuthSignIn(userId: user.id));
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

    unawaited(MonitoringService().breadcrumbAuthSignOut());

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

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  () {
    return AuthNotifier();
  },
);
