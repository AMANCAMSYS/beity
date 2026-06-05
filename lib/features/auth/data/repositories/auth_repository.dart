import 'package:sawa/core/local_database/daos/users_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class EmailConfirmationRequiredException extends AuthException {
  final String email;

  const EmailConfirmationRequiredException({required this.email})
    : super(
        'verification_email_sent',
        statusCode: '200',
        code: 'email_confirmation_required',
      );
}

abstract class AuthRepository {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? language,
  });

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? country,
    String? dialect,
    String? language,
  });

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String extension,
    required String contentType,
  });

  Stream<AuthState> get authStateChanges;
}

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;
  final UsersDao? _usersDaoOverride;

  AuthRepositoryImpl(this._client, {UsersDao? usersDao})
    : _usersDaoOverride = usersDao;

  UsersDao get _usersDao =>
      _usersDaoOverride ?? UsersDao(LocalDatabaseService.instance);

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? language,
  }) async {
    try {
      final metadata = <String, dynamic>{'full_name': fullName};
      if (language != null) metadata['language'] = language;

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user == null) {
        throw const AuthException('signup_failed');
      }

      // Supabase returns a user without a session when email confirmation is enabled.
      if (response.session == null) {
        throw EmailConfirmationRequiredException(email: email);
      }

      final userProfile = await _client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      final model = UserModel.fromJson(userProfile);

      await _saveUserProfile(model);

      return model;
    } on EmailConfirmationRequiredException {
      rethrow;
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AuthException('db_error: ${e.message}');
    } catch (e) {
      throw AuthException('unexpected_error_retry: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('login_failed');
      }

      final userProfile = await _client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      final model = UserModel.fromJson(userProfile);

      await _saveUserProfile(model);

      return model;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('unexpected_error_retry: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final response = await SupabaseService.signInWithGoogle();

      if (response.user == null) {
        throw const AuthException('google_login_failed');
      }

      // Check if user profile exists, create if not
      final existingUser = await _client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      Map<String, dynamic> userProfile;
      if (existingUser == null) {
        // Create user profile from Google data
        final metadata = response.user!.userMetadata ?? {};
        userProfile = await _client
            .from('users')
            .insert({
              'id': response.user!.id,
              'email': response.user!.email ?? '',
              'full_name':
                  metadata['full_name'] ?? metadata['name'] ?? 'مستخدم',
              'avatar_url': metadata['avatar_url'] ?? metadata['picture'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
      } else {
        userProfile = existingUser;
      }

      final model = UserModel.fromJson(userProfile);

      await _saveUserProfile(model);

      return model;
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AuthException('db_error: ${e.message}');
    } catch (e) {
      throw AuthException('unexpected_error_retry: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.remove('last_logged_in_user_id');
    } catch (_) {}
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final userProfile = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final model = UserModel.fromJson(userProfile);

      await _saveUserProfile(model);

      return model;
    } catch (e) {
      final localProfile = await _getLocalUserProfile(user.id);
      if (localProfile != null) return localProfile;

      // Fallback to auth metadata if profile is not cached yet
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String? ?? 'مستخدم',
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? country,
    String? dialect,
    String? language,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('must_login_first');
    }

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (country != null) updates['country'] = country;
      if (dialect != null) updates['dialect'] = dialect;
      if (language != null) updates['language'] = language;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final metadataUpdates = <String, dynamic>{};
      if (fullName != null) metadataUpdates['full_name'] = fullName;
      if (avatarUrl != null) metadataUpdates['avatar_url'] = avatarUrl;
      if (language != null) metadataUpdates['language'] = language;

      if (metadataUpdates.isNotEmpty) {
        final currentMetadata = Map<String, dynamic>.from(
          user.userMetadata ?? const <String, dynamic>{},
        )..addAll(metadataUpdates);
        await _client.auth.updateUser(UserAttributes(data: currentMetadata));
      }

      final userProfile = await _client
          .from('users')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();

      final model = UserModel.fromJson(userProfile);

      await _saveUserProfile(model);

      return model;
    } catch (e) {
      throw AuthException('profile_update_failed: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('must_login_first');
    }

    final normalizedExtension = extension.toLowerCase().replaceAll('.', '');
    final safeExtension = switch (normalizedExtension) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
    final path = '${user.id}/avatar.$safeExtension';
    final version = DateTime.now().millisecondsSinceEpoch;

    try {
      await _client.storage
          .from('user-avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = _client.storage.from('user-avatars').getPublicUrl(path);
      return '$publicUrl?v=$version';
    } on StorageException catch (e) {
      throw AuthException('error_file_upload: ${e.message}');
    } catch (e) {
      throw AuthException('error_file_upload: ${e.toString()}');
    }
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> _saveUserProfile(UserModel model) async {
    try {
      await _usersDao.upsertUser(model, lastSeenAt: DateTime.now());
    } catch (_) {}

    // Keep only the legacy user id marker for services that need a scoped
    // local queue before Supabase auth is fully hydrated. Profile data now
    // lives in Drift `local_users`.
    try {
      final prefs = AppPreferences.instance;
      await prefs.setString('last_logged_in_user_id', model.id);
    } catch (_) {}
  }

  Future<UserModel?> _getLocalUserProfile(String userId) async {
    try {
      return await _usersDao.getUser(userId);
    } catch (_) {
      return null;
    }
  }
}
