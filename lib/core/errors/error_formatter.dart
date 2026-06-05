import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_exception.dart';
import '../localization/app_localizations.dart';

class ErrorFormatter {
  static String format(Object exception, BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = container.read(appLocalizationsProvider);
    return formatWithL10n(exception, l10n);
  }

  static String formatWithL10n(Object exception, AppLocalizations l10n) {
    if (exception is ValidationException) {
      return l10n.translate(exception.message);
    }

    // 1. Check for network and internet connectivity errors
    if (exception is SocketException ||
        exception is HttpException ||
        exception.toString().contains('SocketException') ||
        exception.toString().contains('Failed host lookup') ||
        exception.toString().contains('NetworkEpoch') ||
        exception.toString().contains('connection error') ||
        exception.toString().contains('ClientException')) {
      return l10n.translate('network_error');
    }

    // 2. Check for database and PostgreSql errors
    if (exception is PostgrestException) {
      final code = exception.code;
      switch (code) {
        case '23505': // Unique violation (e.g. item already exists)
          return l10n.translate('db_duplicate_error');
        case '23503': // Foreign key violation
          return l10n.translate('db_relation_error');
        case '42P01': // Undefined table
          return l10n.translate('db_system_error');
        default:
          return '${l10n.translate('database_error')}: ${exception.message}';
      }
    }

    // 3. Check for Supabase Auth errors
    if (exception is AuthException) {
      final message = exception.message;
      if (message.contains('Invalid login credentials')) {
        return l10n.translate('invalid_credentials');
      }
      if (message.contains('Email already registered') || message.contains('already exists')) {
        return l10n.translate('email_already_registered');
      }
      if (message.contains('Password should be')) {
        return l10n.translate('weak_password');
      }
      if (message.contains('User not found')) {
        return l10n.translate('user_not_found');
      }
      if (message.contains('فشل إنشاء الحساب') || message.contains('signup_failed') || message.contains('Failed to create account')) {
        return l10n.translate('signup_failed');
      }
      if (message.contains('فشل تسجيل الدخول عبر Google') || message.contains('google_login_failed') || message.contains('Google sign-in failed')) {
        return l10n.translate('google_login_failed');
      }
      if (message.contains('فشل تسجيل الدخول') || message.contains('login_failed') || message.contains('Failed to login')) {
        return l10n.translate('login_failed');
      }
      if (message.contains('فشل تحديث الملف الشخصي') || message.contains('profile_update_failed') || message.contains('Failed to update profile')) {
        return l10n.translate('profile_update_failed');
      }
      if (message.contains('فشل رفع الصورة') || message.contains('error_file_upload') || message.contains('Failed to upload image') || message.contains('uploading the file')) {
        return l10n.translate('error_file_upload');
      }
      return message;
    }

    // 4. Fallback for generic or unexpected exceptions
    final errStr = exception.toString();
    if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
      return l10n.translate('network_error');
    }
    if (errStr.contains('يجب تسجيل الدخول أولاً') || errStr.contains('must login first') || errStr.contains('User not authenticated') || errStr.contains('must_login_first')) {
      return l10n.translate('must_login_first');
    }
    if (errStr.contains('لم يتم تحديد المنزل بشكل صحيح') || errStr.contains('home is not selected') || errStr.contains('error_home_not_selected')) {
      return l10n.translate('error_home_not_selected');
    }
    if (errStr.contains('لا يمكن تعديل الوحدات الافتراضية') || errStr.contains('لا يمكن تعديل التصنيفات الافتراضية') || errStr.contains('cannot edit default') || errStr.contains('cannot_edit_default_categories') || errStr.contains('cannot_edit_default_units')) {
      return l10n.translate('error_cannot_edit_default');
    }
    if (errStr.contains('لا يمكن حذف الوحدات الافتراضية') || errStr.contains('لا يمكن حذف التصنيفات الافتراضية') || errStr.contains('cannot delete default') || errStr.contains('cannot_delete_default_categories') || errStr.contains('cannot_delete_default_units')) {
      return l10n.translate('error_cannot_delete_default');
    }
    if (errStr.contains('اسم الوحدة موجود بالفعل') || errStr.contains('اسم التصنيف موجود بالفعل') || errStr.contains('name already exists') || errStr.contains('category_name_exists') || errStr.contains('unit_name_exists')) {
      return l10n.translate('error_name_exists');
    }
    if (errStr.contains('رمز الوحدة موجود بالفعل') || errStr.contains('symbol already exists') || errStr.contains('unit_symbol_exists')) {
      return l10n.translate('error_symbol_exists');
    }
    if (errStr.contains('اسم القائمة مطلوب') || errStr.contains('list name is required') || errStr.contains('list_name_required') || errStr.contains('error_list_name_required')) {
      return l10n.translate('error_list_name_required');
    }
    if (errStr.contains('اسم المنتج مطلوب') || errStr.contains('product name is required') || errStr.contains('product_name_required') || errStr.contains('error_product_name_required')) {
      return l10n.translate('error_product_name_required');
    }
    if (errStr.contains('الكمية يجب أن تكون أكبر من صفر') || errStr.contains('quantity must be greater than zero') || errStr.contains('quantity_must_be_greater_than_zero') || errStr.contains('error_quantity_must_be_greater_than_zero')) {
      return l10n.translate('error_quantity_must_be_greater_than_zero');
    }
    if (errStr.contains('هذا المستخدم عضو بالفعل في المنزل') || errStr.contains('already a member') || errStr.contains('already_a_member')) {
      return l10n.translate('error_already_member');
    }
    if (errStr.contains('يوجد دعوة معلقة بالفعل لهذا البريد الإلكتروني') || errStr.contains('pending invitation already exists') || errStr.contains('pending_invitation_exists')) {
      return l10n.translate('error_pending_invitation_exists');
    }
    if (errStr.contains('ليس لديك صلاحية لإرسال دعوات') || errStr.contains('no permission to send') || errStr.contains('no_permission_to_invite')) {
      return l10n.translate('error_no_permission_to_invite');
    }
    if (errStr.contains('ليس لديك صلاحية لإلغاء هذه الدعوة') || errStr.contains('no_permission_to_cancel') || errStr.contains('no permission to cancel')) {
      return l10n.translate('no_permission_to_cancel');
    }
    if (errStr.contains('ليس لديك صلاحية لرفض هذه الدعوة') || errStr.contains('no_permission_to_decline') || errStr.contains('no permission to decline')) {
      return l10n.translate('no_permission_to_decline');
    }
    if (errStr.contains('الدعوة غير موجودة أو تم التعامل معها مسبقاً') || errStr.contains('invitation does not exist') || errStr.contains('invitation_not_found_or_handled') || errStr.contains('invitation_not_found')) {
      return l10n.translate('error_invitation_not_found');
    }
    if (errStr.contains('الدعوة منتهية الصلاحية') || errStr.contains('invitation is expired') || errStr.contains('invitation_expired')) {
      return l10n.translate('error_invitation_expired');
    }
    if (errStr.contains('غير مصرح لك بقبول هذه الدعوة') || errStr.contains('not authorized to accept') || errStr.contains('not_authorized_accept_invitation')) {
      return l10n.translate('error_not_authorized_accept_invitation');
    }
    if (errStr.contains('رمز الدعوة غير صالح') || errStr.contains('معرف الدعوة غير صالح') || errStr.contains('invalid_invitation_code') || errStr.contains('invalid_invitation_id')) {
      return l10n.translate('error_invalid_invitation_code');
    }
    if (errStr.contains('تعذر إنشاء رمز الدعوة') || errStr.contains('invitation_code_generation_failed') || errStr.contains('gen_random_bytes')) {
      return l10n.translate('invitation_code_generation_failed');
    }
    if (errStr.contains('الدور غير صالح') || errStr.contains('invalid_role')) {
      return l10n.translate('error_invalid_role');
    }
    if (errStr.contains('معرف المنزل والمستخدم مطلوبان') || errStr.contains('home_user_required')) {
      return l10n.translate('error_home_user_required');
    }
    if (errStr.contains('معرف المنزل والمالك الجديد مطلوبان') || errStr.contains('home_owner_required')) {
      return l10n.translate('error_home_owner_required');
    }
    if (errStr.contains('فقط المالك يمكنه تغيير الأدوار') || errStr.contains('only_owner_can_change_roles')) {
      return l10n.translate('error_only_owner_can_change_roles');
    }
    if (errStr.contains('لا يمكن تغيير دور المالك') || errStr.contains('cannot_change_owner_role')) {
      return l10n.translate('error_cannot_change_owner_role');
    }
    if (errStr.contains('أنت لست عضواً في هذا المنزل') || errStr.contains('أنت لست عضواً في هذا منزل') || errStr.contains('not_member_of_home')) {
      return l10n.translate('error_not_member_of_home');
    }
    if (errStr.contains('العضو غير موجود') || errStr.contains('member_not_found')) {
      return l10n.translate('error_member_not_found');
    }
    if (errStr.contains('لا يمكن إزالة المالك') || errStr.contains('cannot_remove_owner')) {
      return l10n.translate('error_cannot_remove_owner');
    }
    if (errStr.contains('لا يمكن للمدير إزالة مدير آخر') || errStr.contains('admin_cannot_remove_admin')) {
      return l10n.translate('error_admin_cannot_remove_admin');
    }
    if (errStr.contains('لا يمكن إزالة نفسك، يجب نقل الملكية أولاً') || errStr.contains('cannot_remove_self')) {
      return l10n.translate('error_cannot_remove_self_transfer_first');
    }
    if (errStr.contains('فقط المالك يمكنه نقل الملكية') || errStr.contains('only_owner_can_transfer_ownership')) {
      return l10n.translate('error_only_owner_can_transfer_ownership');
    }
    if (errStr.contains('المالك الجديد يجب أن يكون عضواً في المنزل') || errStr.contains('new_owner_must_be_member')) {
      return l10n.translate('error_new_owner_must_be_member');
    }
    if (errStr.contains('invalid_email_format')) {
      return l10n.translate('error_invalid_email_format');
    }
    if (errStr.contains('invalid_role_selected')) {
      return l10n.translate('error_invalid_role_selected');
    }
    if (errStr.contains('المنتج غير موجود في المخزون') || errStr.contains('error_item_not_found_in_inventory')) {
      return l10n.translate('error_item_not_found_in_inventory');
    }
    if (errStr.contains('لا يوجد منزل نشط') || errStr.contains('no active home') || errStr.contains('no_active_home') || errStr.contains('error_no_active_home')) {
      return l10n.translate('error_no_active_home');
    }
    if (errStr.contains('تم الوصول إلى الحد الأقصى لعدد المنازل') || errStr.contains('maximum number of homes reached') || errStr.contains('max_homes_reached')) {
      return l10n.translate('max_homes_reached');
    }
    if (errStr.contains('فشل إنشاء المنزل') || errStr.contains('create_home_failed')) {
      return l10n.translate('create_home_failed', arguments: {'error': ''});
    }
    if (errStr.contains('فشل حذف المنزل') || errStr.contains('delete_home_failed')) {
      return l10n.translate('delete_home_failed', arguments: {'error': ''});
    }
    if (errStr.contains('فشل إزالة العضو') || errStr.contains('remove_member_failed')) {
      return l10n.translate('remove_member_failed', arguments: {'error': ''});
    }
    if (errStr.contains('فشل تحديث العملة') || errStr.contains('currency_update_failed') || errStr.contains('currency_updated_failed')) {
      return l10n.translate('currency_update_failed', arguments: {'error': ''});
    }

    // AI suggestion exception strings
    if (errStr.contains('تعذر قراءة الاقتراحات، حاول مرة أخرى') || errStr.contains('Invalid response format') || errStr.contains('ai_error_parsing')) {
      return l10n.translate('ai_error_parsing');
    }
    if (errStr.contains('طلب غير صالح') || errStr.contains('Invalid request') || errStr.contains('invalid_request')) {
      return l10n.translate('error_generic');
    }
    if (errStr.contains('تعذر إنشاء الاقتراحات، حاول مرة أخرى') || errStr.contains('Failed to generate suggestions')) {
      return l10n.translate('ai_error_parsing');
    }
    if (errStr.contains('الخدمة غير متاحة') || errStr.contains('Service unavailable') || errStr.contains('service_unavailable')) {
      return l10n.translate('network_error');
    }

    return l10n.translate('unexpected_error_retry');
  }
}
