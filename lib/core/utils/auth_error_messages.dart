import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class AuthErrorMessages {
  static String mapError(BuildContext context, String code) {
    switch (code) {
      case 'invalid_credentials':
        return context.translate('invalid_credentials');
      case 'user_already_registered':
      case 'email_address_invalid':
        return context.translate('email_already_registered');
      case 'weak_password':
        return context.translate('weak_password');
      case 'invalid_email':
        return context.translate('email_invalid');
      case 'network_error':
        return context.translate('network_error');
      case 'session_expired':
        return context.translate('session_expired');
      default:
        return context.translate('login_error_generic');
    }
  }

  static String validateEmail(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.translate('email_required');
    }
    if (!RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(value)) {
      return context.translate('email_invalid');
    }
    return '';
  }

  static String validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.translate('password_required');
    }
    if (value.length < 8) {
      return context.translate('password_too_short');
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return context.translate('password_needs_uppercase');
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return context.translate('password_needs_digit');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/~`]').hasMatch(value)) {
      return context.translate('password_needs_special');
    }
    return '';
  }

  static String validateName(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.translate('name_required');
    }
    if (value.length > 100) {
      return context.translate('name_too_long');
    }
    return '';
  }
}
