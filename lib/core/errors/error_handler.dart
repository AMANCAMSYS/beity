import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

import 'app_exception.dart';

class ErrorHandler {
  static ErrorHandlerMessage mapExceptionToMessage(
    dynamic exception,
    BuildContext context,
  ) {
    if (exception is NetworkException) {
      return ErrorHandlerMessage(
        message: context.translate('network_error_offline_sync'),
        recoveryAction: RecoveryAction.queueAndRetry,
        icon: Icons.wifi_off,
      );
    }

    if (exception is AuthException) {
      return ErrorHandlerMessage(
        message: context.translate('session_expired'),
        recoveryAction: RecoveryAction.reauth,
        icon: Icons.lock_outline,
      );
    }

    if (exception is PermissionException) {
      return ErrorHandlerMessage(
        message: context.translate('error_no_home_access'),
        recoveryAction: RecoveryAction.navigateToHomes,
        icon: Icons.no_accounts,
      );
    }

    if (exception is DatabaseException) {
      return ErrorHandlerMessage(
        message: context.translate('error_db_system_generic'),
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
      message: context.translate('unexpected_error_report'),
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
