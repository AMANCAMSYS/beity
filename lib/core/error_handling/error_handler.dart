import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

class ErrorHandler {
  static ErrorHandlerMessage mapExceptionToMessage(dynamic exception) {
    if (exception is NetworkException) {
      return ErrorHandlerMessage(
        message: 'You\'re offline. Changes will sync when you\'re back online.',
        recoveryAction: RecoveryAction.queueAndRetry,
        icon: Icons.wifi_off,
      );
    }

    if (exception is AuthException) {
      return ErrorHandlerMessage(
        message: 'Your session expired. Please sign in again.',
        recoveryAction: RecoveryAction.reauth,
        icon: Icons.lock_outline,
      );
    }

    if (exception is PermissionException) {
      return ErrorHandlerMessage(
        message: 'You no longer have access to this home.',
        recoveryAction: RecoveryAction.navigateToHomes,
        icon: Icons.no_accounts,
      );
    }

    if (exception is DatabaseException) {
      return ErrorHandlerMessage(
        message: 'Something went wrong on our end. Please try again.',
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
      message: 'An unexpected error occurred. Please try again or report this.',
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
