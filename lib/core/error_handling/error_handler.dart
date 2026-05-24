import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

class ErrorHandler {
  static ErrorHandlerMessage mapExceptionToMessage(dynamic exception) {
    if (exception is NetworkException) {
      return ErrorHandlerMessage(
        message: 'أنت غير متصل بالإنترنت. سيتم مزامنة التغييرات عند عودة الاتصال.',
        recoveryAction: RecoveryAction.queueAndRetry,
        icon: Icons.wifi_off,
      );
    }

    if (exception is AuthException) {
      return ErrorHandlerMessage(
        message: 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.',
        recoveryAction: RecoveryAction.reauth,
        icon: Icons.lock_outline,
      );
    }

    if (exception is PermissionException) {
      return ErrorHandlerMessage(
        message: 'لم يعد لديك وصول إلى هذا المنزل.',
        recoveryAction: RecoveryAction.navigateToHomes,
        icon: Icons.no_accounts,
      );
    }

    if (exception is DatabaseException) {
      return ErrorHandlerMessage(
        message: 'حدث خطأ من جانبنا. يرجى المحاولة مرة أخرى.',
        recoveryAction: RecoveryAction.retry,
        icon: Icons.error_outline,
      );
    }

    if (exception is ValidationException) {
      return ErrorHandlerMessage(
        message: exception.message,
        recoveryAction: RecoveryAction.dismiss,
        icon: Icons.warning_amber,
      );
    }

    // Default for unknown errors
    return ErrorHandlerMessage(
      message: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى أو الإبلاغ عن المشكلة.',
      recoveryAction: RecoveryAction.retryAndReport,
      icon: Icons.error_outline,
    );
  }
}

enum RecoveryAction {
  queueAndRetry,
  reauth,
  navigateToHomes,
  retry,
  dismiss,
  retryAndReport,
}

class ErrorHandlerMessage {
  final String message;
  final RecoveryAction recoveryAction;
  final IconData icon;

  const ErrorHandlerMessage({
    required this.message,
    required this.recoveryAction,
    required this.icon,
  });
}
