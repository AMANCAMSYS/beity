import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/app_exception.dart';
import 'package:sawa/core/errors/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('should map NetworkException correctly', () {
      final msg = ErrorHandler.mapExceptionToMessage(const NetworkException(message: 'network error'));
      expect(msg.recoveryAction, RecoveryAction.queueAndRetry);
      expect(msg.icon, Icons.wifi_off);
    });

    test('should map AuthException correctly', () {
      final msg = ErrorHandler.mapExceptionToMessage(const AuthException(message: 'auth error'));
      expect(msg.recoveryAction, RecoveryAction.reauth);
      expect(msg.icon, Icons.lock_outline);
    });

    test('should map PermissionException correctly', () {
      final msg = ErrorHandler.mapExceptionToMessage(const PermissionException(message: 'permission error'));
      expect(msg.recoveryAction, RecoveryAction.navigateToHomes);
      expect(msg.icon, Icons.no_accounts);
    });

    test('should map DatabaseException correctly', () {
      final msg = ErrorHandler.mapExceptionToMessage(const DatabaseException(message: 'database error'));
      expect(msg.recoveryAction, RecoveryAction.retry);
      expect(msg.icon, Icons.error_outline);
    });

    test('should map ValidationException correctly', () {
      final msg = ErrorHandler.mapExceptionToMessage(const ValidationException(message: 'Required field'));
      expect(msg.recoveryAction, RecoveryAction.dismiss);
      expect(msg.icon, Icons.warning_amber);
      expect(msg.message, 'Required field');
    });

    test('should return default message for unknown exception', () {
      final msg = ErrorHandler.mapExceptionToMessage(Exception('Unknown'));
      expect(msg.recoveryAction, RecoveryAction.retryAndReport);
      expect(msg.icon, Icons.error_outline);
    });
  });
}
