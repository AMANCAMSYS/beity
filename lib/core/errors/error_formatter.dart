import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'app_exception.dart';
import '../localization/app_localizations.dart';

class ErrorFormatter {
  static String format(Object exception, BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = container.read(appLocalizationsProvider);
    return formatWithL10n(exception, l10n);
  }

  static String formatWithL10n(Object exception, AppLocalizations l10n) {
    // 1. Type-based checks (fast path)
    final typeResult = _handleTypeBasedError(exception, l10n);
    if (typeResult != null) return typeResult;

    // 2. String pattern matching (fallback)
    return _handleStringBasedError(exception.toString(), l10n);
  }

  static String? _handleTypeBasedError(
    Object exception,
    AppLocalizations l10n,
  ) {
    if (exception is ValidationException) {
      return l10n.translate(exception.message);
    }

    if (exception is SocketException ||
        exception is HttpException ||
        _matchesAny(exception.toString(), _networkPatterns)) {
      return l10n.translate('network_error');
    }

    if (exception is PostgrestException) {
      return _handlePostgrestException(exception, l10n);
    }

    if (exception is AuthException) {
      return _handleAuthException(exception, l10n);
    }

    return null;
  }

  static String _handlePostgrestException(
    PostgrestException exception,
    AppLocalizations l10n,
  ) {
    final code = exception.code;
    switch (code) {
      case '23505':
        return l10n.translate('db_duplicate_error');
      case '23503':
        return l10n.translate('db_relation_error');
      case '42P01':
        return l10n.translate('db_system_error');
      case '42501':
        return l10n.translate('error_no_permission');
      case 'PGRST116':
        return l10n.translate('error_item_not_found_in_inventory');
      case '23514':
        return l10n.translate('db_system_error');
      default:
        return '${l10n.translate('database_error')}: ${exception.message}';
    }
  }

  static String _handleAuthException(
    AuthException exception,
    AppLocalizations l10n,
  ) {
    final message = exception.message;
    for (final entry in _authErrorMappings.entries) {
      if (_matchesAny(message, entry.key)) {
        return l10n.translate(entry.value);
      }
    }
    return message;
  }

  static String _handleStringBasedError(String errStr, AppLocalizations l10n) {
    for (final entry in _stringErrorMappings.entries) {
      if (_matchesAny(errStr, entry.key)) {
        return l10n.translate(entry.value);
      }
    }
    return l10n.translate('unexpected_error_retry');
  }

  static bool _matchesAny(String input, List<String> patterns) {
    for (final pattern in patterns) {
      if (input.contains(pattern)) return true;
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Error Pattern Mappings
  // ─────────────────────────────────────────────────────────────────────

  static const _networkPatterns = [
    'SocketException',
    'Failed host lookup',
    'NetworkEpoch',
    'connection error',
    'ClientException',
  ];

  static const _authErrorMappings = <List<String>, String>{
    ['Invalid login credentials']: 'invalid_credentials',
    ['Email already registered', 'already exists']: 'email_already_registered',
    ['Password should be']: 'weak_password',
    ['User not found']: 'user_not_found',
    ['فشل إنشاء الحساب', 'signup_failed', 'Failed to create account']:
        'signup_failed',
    [
      'فشل تسجيل الدخول عبر Google',
      'google_login_failed',
      'Google sign-in failed',
    ]: 'google_login_failed',
    ['فشل تسجيل الدخول', 'login_failed', 'Failed to login']: 'login_failed',
    [
      'فشل تحديث الملف الشخصي',
      'profile_update_failed',
      'Failed to update profile',
    ]: 'profile_update_failed',
    [
      'فشل رفع الصورة',
      'error_file_upload',
      'Failed to upload image',
      'uploading the file',
    ]: 'error_file_upload',
  };

  static const _stringErrorMappings = <List<String>, String>{
    // Network
    ['SocketException', 'Failed host lookup']: 'network_error',

    // Auth
    [
      'يجب تسجيل الدخول أولاً',
      'must login first',
      'User not authenticated',
      'must_login_first',
    ]: 'must_login_first',

    // Home
    [
      'لم يتم تحديد المنزل بشكل صحيح',
      'home is not selected',
      'error_home_not_selected',
    ]: 'error_home_not_selected',
    [
      'لا يوجد منزل نشط',
      'no active home',
      'no_active_home',
      'error_no_active_home',
    ]: 'error_no_active_home',
    [
      'تم الوصول إلى الحد الأقصى لعدد المنازل',
      'maximum number of homes reached',
      'max_homes_reached',
    ]: 'max_homes_reached',
    ['فشل إنشاء المنزل', 'create_home_failed']: 'create_home_failed',
    ['فشل حذف المنزل', 'delete_home_failed']: 'delete_home_failed',

    // Categories & Units
    [
      'لا يمكن تعديل الوحدات الافتراضية',
      'لا يمكن تعديل التصنيفات الافتراضية',
      'cannot edit default',
      'cannot_edit_default_categories',
      'cannot_edit_default_units',
    ]: 'error_cannot_edit_default',
    [
      'لا يمكن حذف الوحدات الافتراضية',
      'لا يمكن حذف التصنيفات الافتراضية',
      'cannot delete default',
      'cannot_delete_default_categories',
      'cannot_delete_default_units',
    ]: 'error_cannot_delete_default',
    [
      'اسم الوحدة موجود بالفعل',
      'اسم التصنيف موجود بالفعل',
      'name already exists',
      'category_name_exists',
      'unit_name_exists',
    ]: 'error_name_exists',
    ['رمز الوحدة موجود بالفعل', 'symbol already exists', 'unit_symbol_exists']:
        'error_symbol_exists',

    // Shopping Lists
    [
      'اسم القائمة مطلوب',
      'list name is required',
      'list_name_required',
      'error_list_name_required',
    ]: 'error_list_name_required',
    [
      'اسم المنتج مطلوب',
      'product name is required',
      'product_name_required',
      'error_product_name_required',
    ]: 'error_product_name_required',
    [
      'الكمية يجب أن تكون أكبر من صفر',
      'quantity must be greater than zero',
      'quantity_must_be_greater_than_zero',
      'error_quantity_must_be_greater_than_zero',
    ]: 'error_quantity_must_be_greater_than_zero',

    // Members & Invitations
    [
      'هذا المستخدم عضو بالفعل في المنزل',
      'already a member',
      'already_a_member',
    ]: 'error_already_member',
    [
      'يوجد دعوة معلقة بالفعل لهذا البريد الإلكتروني',
      'pending invitation already exists',
      'pending_invitation_exists',
    ]: 'error_pending_invitation_exists',
    [
      'ليس لديك صلاحية لإرسال دعوات',
      'no permission to send',
      'no_permission_to_invite',
    ]: 'error_no_permission_to_invite',
    [
      'ليس لديك صلاحية لإلغاء هذه الدعوة',
      'no_permission_to_cancel',
      'no permission to cancel',
    ]: 'no_permission_to_cancel',
    [
      'ليس لديك صلاحية لرفض هذه الدعوة',
      'no_permission_to_decline',
      'no permission to decline',
    ]: 'no_permission_to_decline',
    [
      'الدعوة غير موجودة أو تم التعامل معها مسبقاً',
      'invitation does not exist',
      'invitation_not_found_or_handled',
      'invitation_not_found',
    ]: 'error_invitation_not_found',
    ['الدعوة منتهية الصلاحية', 'invitation is expired', 'invitation_expired']:
        'error_invitation_expired',
    [
      'غير مصرح لك بقبول هذه الدعوة',
      'not authorized to accept',
      'not_authorized_accept_invitation',
    ]: 'error_not_authorized_accept_invitation',
    [
      'رمز الدعوة غير صالح',
      'معرف الدعوة غير صالح',
      'invalid_invitation_code',
      'invalid_invitation_id',
    ]: 'error_invalid_invitation_code',
    [
      'تعذر إنشاء رمز الدعوة',
      'invitation_code_generation_failed',
      'gen_random_bytes',
    ]: 'invitation_code_generation_failed',
    ['الدور غير صالح', 'invalid_role']: 'error_invalid_role',
    ['invalid_email_format']: 'error_invalid_email_format',
    ['invalid_role_selected']: 'error_invalid_role_selected',

    // Home Members
    ['معرف المنزل والمستخدم مطلوبان', 'home_user_required']:
        'error_home_user_required',
    ['معرف المنزل والمالك الجديد مطلوبان', 'home_owner_required']:
        'error_home_owner_required',
    ['فقط المالك يمكنه تغيير الأدوار', 'only_owner_can_change_roles']:
        'error_only_owner_can_change_roles',
    ['لا يمكن تغيير دور المالك', 'cannot_change_owner_role']:
        'error_cannot_change_owner_role',
    [
      'أنت لست عضواً في هذا المنزل',
      'أنت لست عضواً في هذا منزل',
      'not_member_of_home',
    ]: 'error_not_member_of_home',
    ['العضو غير موجود', 'member_not_found']: 'error_member_not_found',
    ['لا يمكن إزالة المالك', 'cannot_remove_owner']:
        'error_cannot_remove_owner',
    ['لا يمكن للمدير إزالة مدير آخر', 'admin_cannot_remove_admin']:
        'error_admin_cannot_remove_admin',
    ['لا يمكن إزالة نفسك، يجب نقل الملكية أولاً', 'cannot_remove_self']:
        'error_cannot_remove_self_transfer_first',
    ['فقط المالك يمكنه نقل الملكية', 'only_owner_can_transfer_ownership']:
        'error_only_owner_can_transfer_ownership',
    ['المالك الجديد يجب أن يكون عضواً في المنزل', 'new_owner_must_be_member']:
        'error_new_owner_must_be_member',
    ['فشل إزالة العضو', 'remove_member_failed']: 'remove_member_failed',
    ['فشل تحديث العملة', 'currency_update_failed', 'currency_updated_failed']:
        'currency_update_failed',

    // Inventory
    ['المنتج غير موجود في المخزون', 'error_item_not_found_in_inventory']:
        'error_item_not_found_in_inventory',

    // AI Suggestions
    [
      'تعذر قراءة الاقتراحات، حاول مرة أخرى',
      'Invalid response format',
      'ai_error_parsing',
    ]: 'ai_error_parsing',
    ['طلب غير صالح', 'Invalid request', 'invalid_request']: 'error_generic',
    ['تعذر إنشاء الاقتراحات، حاول مرة أخرى', 'Failed to generate suggestions']:
        'ai_error_parsing',
    ['الخدمة غير متاحة', 'Service unavailable', 'service_unavailable']:
        'network_error',
  };
}
