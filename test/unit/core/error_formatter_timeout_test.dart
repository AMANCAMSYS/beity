import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/error_formatter.dart' as ef;
import 'package:sawa/core/localization/app_localizations.dart';

void main() {
  testWidgets('ErrorFormatter should handle TimeoutException', (tester) async {
    final localizations = AppLocalizations(const Locale('en', 'US'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLocalizationsProvider.overrideWithValue(localizations)],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final msg = ef.ErrorFormatter.format(
                TimeoutException('Connection timed out'),
                context,
              );
              expect(msg, localizations.translate('unexpected_error_retry'));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });

  test('formatWithL10n handles TimeoutException', () {
    final localizations = AppLocalizations(const Locale('en', 'US'));

    final msg = ef.ErrorFormatter.formatWithL10n(
      TimeoutException('Connection timed out'),
      localizations,
    );

    expect(msg, localizations.translate('unexpected_error_retry'));
  });

  test('formatWithL10n handles TimeoutException with custom duration', () {
    final localizations = AppLocalizations(const Locale('en', 'US'));

    final msg = ef.ErrorFormatter.formatWithL10n(
      TimeoutException('Request timed out', const Duration(seconds: 30)),
      localizations,
    );

    expect(msg, localizations.translate('unexpected_error_retry'));
  });
}
