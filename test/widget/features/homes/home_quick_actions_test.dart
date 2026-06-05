import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/home/presentation/widgets/home_quick_actions.dart';

void main() {
  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        appLocalizationsProvider.overrideWithValue(
          AppLocalizations(const Locale('en', 'US')),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: HomeQuickActions(homeId: 'home-1')),
      ),
    );
  }

  testWidgets('home shortcuts surface cross-feature actions', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
  });

  testWidgets('home shortcuts no longer show list-specific actions', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Add Item'), findsNothing);
    expect(find.text('Shopping Mode'), findsNothing);
    expect(find.text('Smart Suggestions'), findsNothing);
  });
}
