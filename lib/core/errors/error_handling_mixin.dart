import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../monitoring/monitoring_service.dart';
import 'error_handler.dart';
import 'package:beity/core/localization/app_localizations.dart';

mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  Future<void> handleError(
    dynamic error,
    StackTrace stackTrace, {
    String? errorContext,
    VoidCallback? onRetry,
  }) async {
    // Log to monitoring
    await MonitoringService().logError(
      error,
      stackTrace,
      reason: errorContext,
    );

    // Map to user-friendly message
    final errorInfo = ErrorHandler.mapExceptionToMessage(error);

    if (!mounted) return;

    // Show appropriate UI based on recovery action
    switch (errorInfo.recoveryAction) {
      case RecoveryAction.queueAndRetry:
        _showSnackBar(
          errorInfo.message,
          action: onRetry != null
              ? SnackBarAction(label: context.translate('retry_action'), onPressed: onRetry)
              : null,
          backgroundColor: AppColors.warning,
        );
        break;

      case RecoveryAction.reauth:
        _showSnackBar(
          errorInfo.message,
          backgroundColor: AppColors.error,
        );
        // Navigate to login after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        });
        break;

      case RecoveryAction.navigateToHomes:
        _showSnackBar(
          errorInfo.message,
          backgroundColor: AppColors.error,
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/homes',
          (route) => false,
        );
        break;

      case RecoveryAction.retry:
        _showSnackBar(
          errorInfo.message,
          action: onRetry != null
              ? SnackBarAction(label: context.translate('retry_action'), onPressed: onRetry)
              : null,
          backgroundColor: AppColors.error,
        );
        break;

      case RecoveryAction.dismiss:
        _showSnackBar(
          errorInfo.message,
          backgroundColor: AppColors.warning,
        );
        break;

      case RecoveryAction.retryAndReport:
        _showSnackBar(
          errorInfo.message,
          action: onRetry != null
              ? SnackBarAction(label: context.translate('retry_action'), onPressed: onRetry)
              : null,
          backgroundColor: AppColors.error,
        );
        break;
    }
  }

  void _showSnackBar(
    String message, {
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
