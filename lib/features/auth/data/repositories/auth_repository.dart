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

      return UserModel.fromJson(userProfile);
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

      return UserModel.fromJson(userProfile);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
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

      return UserModel.fromJson(userProfile);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
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
