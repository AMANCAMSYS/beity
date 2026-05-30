import 'dart:convert';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

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

  Stream<AuthState> get authStateChanges;
}

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        throw const AuthException('فشل إنشاء الحساب');
      }

      // If email confirmation is required, user might be null initially
      if (response.session == null) {
        throw const AuthException(
          'تم إرسال بريد تأكيد، يرجى проверة بريدك الإلكتروني',
        );
      }

      final userProfile = await _client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      final model = UserModel.fromJson(userProfile);
      
      // Cache profile
      try {
        final prefs = AppPreferences.instance;
        final cacheKey = '${response.user!.id}_cached_profile';
        await prefs.setString(cacheKey, jsonEncode(model.toJson()));
        await prefs.setString('last_logged_in_user_id', response.user!.id);
      } catch (_) {}

      return model;
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AuthException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw AuthException('حدث خطأ غير متوقع: ${e.toString()}');
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
        throw const AuthException('فشل تسجيل الدخول');
      }

      final userProfile = await _client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      final model = UserModel.fromJson(userProfile);
      
      // Cache profile
      try {
        final prefs = AppPreferences.instance;
        final cacheKey = '${response.user!.id}_cached_profile';
        await prefs.setString(cacheKey, jsonEncode(model.toJson()));
        await prefs.setString('last_logged_in_user_id', response.user!.id);
      } catch (_) {}

      return model;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('حدث خطأ غير متوقع: ${e.toString()}');
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
    final cacheKey = '${user.id}_cached_profile';

    try {
      final userProfile = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final model = UserModel.fromJson(userProfile);
      
      // Cache profile
      try {
        final prefs = AppPreferences.instance;
        await prefs.setString(cacheKey, jsonEncode(model.toJson()));
        await prefs.setString('last_logged_in_user_id', user.id);
      } catch (_) {}

      return model;
    } catch (e) {
      // Fallback to cache if offline/error
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          return UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        }
      } catch (_) {}

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
      throw const AuthException('يجب تسجيل الدخول أولاً');
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

      final userProfile = await _client
          .from('users')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();

      return UserModel.fromJson(userProfile);
    } catch (e) {
      throw AuthException('فشل تحديث الملف الشخصي: ${e.toString()}');
    }
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
