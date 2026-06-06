import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/app_exception.dart';
import 'package:sawa/core/errors/error_handler.dart';
import 'package:sawa/core/localization/app_localizations.dart';

void main() {
  group('ErrorHandler', () {
    Widget buildTestWidget(Widget Function(BuildContext) builder) {
      return ProviderScope(
        overrides: [
          appLocalizationsProvider.overrideWithValue(
            AppLocalizations(const Locale('en', 'US')),
          ),
        ],
        child: MaterialApp(
          home: Builder(builder: (context) => builder(context)),
        ),
      );
    }

    testWidgets('should map NetworkException correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget((context) {
          final msg = ErrorHandler.mapExceptionToMessage(
            const NetworkException(message: 'network error'),
            context,
          );
          expect(msg.recoveryAction, RecoveryAction.queueAndRetry);
          expect(msg.icon, Icons.wifi_off);
          return const SizedBox();
        }),
      );
    });

    testWidgets('should map AuthException correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget((context) {
          final msg = ErrorHandler.mapExceptionToMessage(
            const AuthException(message: 'auth error'),
            context,
          );
          expect(msg.recoveryAction, RecoveryAction.reauth);
          expect(msg.icon, Icons.lock_outline);
          return const SizedBox();
        }),
      );
    });

    testWidgets('should map PermissionException correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget((context) {
          final msg = ErrorHandler.mapExceptionToMessage(
            const PermissionException(message: 'permission error'),
            context,
          );
          expect(msg.recoveryAction, RecoveryAction.navigateToHomes);
          expect(msg.icon, Icons.no_accounts);
          return const SizedBox();
        }),
      );
    });

    testWidgets('should map DatabaseException correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget((context) {
          final msg = ErrorHandler.mapExceptionToMessage(
            const DatabaseException(message: 'database error'),
            context,
          );
          expect(msg.recoveryAction, RecoveryAction.retry);
          expect(msg.icon, Icons.error_outline);
          return const SizedBox();
        }),
      );
    });

    testWidgets('should map ValidationException correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget((context) {
          final msg = ErrorHandler.mapExceptionToMessage(
            const ValidationException(message: 'Required field'),
            context,
          );
          expect(msg.recoveryAction, RecoveryAction.dismiss);
          expect(msg.icon, Icons.warning_amber);
          expect(msg.message, 'Required field');
          return const SizedBox();
        }),
      );
    });

    testWidgets('should return default message for unknown exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget((context) {
          final msg = ErrorHandler.mapExceptionToMessage(
            Exception('Unknown'),
            context,
          );
          expect(msg.recoveryAction, RecoveryAction.retryAndReport);
          expect(msg.icon, Icons.error_outline);
          return const SizedBox();
        }),
      );
    });
  });
}
