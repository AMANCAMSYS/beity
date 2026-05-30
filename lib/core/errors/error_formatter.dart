import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/app_localizations.dart';

class ErrorFormatter {
  static String format(Object exception, BuildContext context) {
    // 1. Check for network and internet connectivity errors
    if (exception is SocketException ||
        exception is HttpException ||
        exception.toString().contains('SocketException') ||
        exception.toString().contains('Failed host lookup') ||
        exception.toString().contains('NetworkEpoch') ||
        exception.toString().contains('connection error') ||
        exception.toString().contains('ClientException')) {
      return context.translate('network_error');
    }

    // 2. Check for database and PostgreSql errors
    if (exception is PostgrestException) {
      final code = exception.code;
      switch (code) {
        case '23505': // Unique violation (e.g. item already exists)
          return context.translate('db_duplicate_error');
        case '23503': // Foreign key violation
          return context.translate('db_relation_error');
        case '42P01': // Undefined table
          return context.translate('db_system_error');
        default:
          return '${context.translate('database_error')}: ${exception.message}';
      }
    }

    // 3. Check for Supabase Auth errors
    if (exception is AuthException) {
      final message = exception.message;
      if (message.contains('Invalid login credentials')) {
        return context.translate('invalid_credentials');
      }
      if (message.contains('Email already registered') || message.contains('already exists')) {
        return context.translate('email_already_registered');
      }
      if (message.contains('Password should be')) {
        return context.translate('weak_password');
      }
      if (message.contains('User not found')) {
        return context.translate('user_not_found');
      }
      return message;
    }

    // 4. Fallback for generic or unexpected exceptions
    final errStr = exception.toString();
    if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
      return context.translate('network_error');
    }
    
    return context.translate('unexpected_error_retry');
  }
}
