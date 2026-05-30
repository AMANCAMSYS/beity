import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beity/core/errors/error_formatter.dart' as ef;
import 'package:beity/core/localization/app_localizations.dart';

void main() {
  testWidgets('ErrorFormatter should format exceptions correctly with localized messages', (tester) async {
    final localizations = AppLocalizations(const Locale('en', 'US'));
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocalizationsProvider.overrideWithValue(localizations),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              // 1. Test SocketException
              final networkMsg = ef.ErrorFormatter.format(const SocketException('Failed host lookup'), context);
              expect(networkMsg, localizations.translate('network_error'));

              // 2. Test PostgrestException (Unique violation)
              final postgrestMsg = ef.ErrorFormatter.format(
                const PostgrestException(message: 'Duplicate key', code: '23505'),
                context,
              );
              expect(postgrestMsg, localizations.translate('db_duplicate_error'));

              // 3. Test PostgrestException (Foreign key violation)
              final postgrestMsg2 = ef.ErrorFormatter.format(
                const PostgrestException(message: 'Foreign key violation', code: '23503'),
                context,
              );
              expect(postgrestMsg2, localizations.translate('db_relation_error'));

              // 4. Test AuthException
              final authMsg = ef.ErrorFormatter.format(
                const AuthException('Invalid login credentials'),
                context,
              );
              expect(authMsg, localizations.translate('invalid_credentials'));

              // 5. Test generic unexpected exceptions
              final genericMsg = ef.ErrorFormatter.format(Exception('Some random error'), context);
              expect(genericMsg, localizations.translate('unexpected_error_retry'));

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}
