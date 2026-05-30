import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'app_exception.dart';

class SupabaseErrorMapper {
  SupabaseErrorMapper._();

  static AppException mapError(Object error) {
    if (error is PostgrestException) {
      return _mapPostgrestError(error);
    }
    if (error is AuthException) {
      return _mapAuthError(error);
    }
    if (error is StorageException) {
      return _mapStorageError(error);
    }

    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return NetworkException(
        message: 'أنت غير متصل بالإنترنت. سيتم مزامنة التغييرات عند عودة الاتصال.',
        originalError: error,
      );
    }

    if (msg.contains('jwt') || msg.contains('unauthorized') || msg.contains('401')) {
      return AuthException(
        message: 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.',
        originalError: error,
      );
    }

    if (msg.contains('access denied') || msg.contains('403')) {
      return PermissionException(
        message: 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
        originalError: error,
      );
    }

    return DatabaseException(
      message: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
      originalError: error,
    );
  }

  static AppException _mapPostgrestError(PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    if (code == '42501' || msg.contains('permission denied') || msg.contains('access denied')) {
      return PermissionException(
        message: 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
        code: code,
        originalError: e,
      );
    }

    if (code == '23505' || msg.contains('duplicate') || msg.contains('unique')) {
      return ValidationException(
        message: 'هذا العنصر موجود بالفعل.',
        code: code,
        originalError: e,
      );
    }

    if (code == '23503' || msg.contains('foreign key') || msg.contains('violates')) {
      return ValidationException(
        message: 'لا يمكن تنفيذ هذا الإجراء بسبب ارتباط بيانات أخرى.',
        code: code,
        originalError: e,
      );
    }

    if (code == '23514' || msg.contains('check') || msg.contains('constraint')) {
      return ValidationException(
        message: 'البيانات المدخلة غير صالحة.',
        code: code,
        originalError: e,
      );
    }

    if (msg.contains('row-level security') || msg.contains('rls')) {
      return PermissionException(
        message: 'ليس لديك صلاحية للوصول إلى هذه البيانات.',
        code: code,
        originalError: e,
      );
    }

    return DatabaseException(
      message: 'حدث خطأ من قاعدة البيانات. يرجى المحاولة مرة أخرى.',
      code: code,
      originalError: e,
    );
  }

  static AppException _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('email not confirmed')) {
      return AuthException(
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
        originalError: e,
      );
    }

    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return ValidationException(
        message: 'هذا البريد الإلكتروني مسجل بالفعل.',
        originalError: e,
      );
    }

    if (msg.contains('password') && msg.contains('short')) {
      return ValidationException(
        message: 'كلمة المرور قصيرة جداً. يجب أن تكون 6 أحرف على الأقل.',
        originalError: e,
      );
    }

    if (msg.contains('expired') || msg.contains('invalid token')) {
      return AuthException(
        message: 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.',
        originalError: e,
      );
    }

    return AuthException(
      message: 'حدث خطأ في المصادقة. يرجى المحاولة مرة أخرى.',
      originalError: e,
    );
  }

  static AppException _mapStorageError(StorageException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('file size') || msg.contains('too large')) {
      return ValidationException(
        message: 'حجم الملف كبير جداً.',
        originalError: e,
      );
    }

    if (msg.contains('not found')) {
      return DatabaseException(
        message: 'الملف المطلوب غير موجود.',
        originalError: e,
      );
    }

    return DatabaseException(
      message: 'حدث خطأ في رفع الملف. يرجى المحاولة مرة أخرى.',
      originalError: e,
    );
  }
}
