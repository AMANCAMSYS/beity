import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beity/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify the app renders
    expect(find.text('مرحباً بك في بيتي'), findsOneWidget);
    expect(find.text('بيتي'), findsOneWidget);
    expect(find.text('قوائم المشتريات'), findsOneWidget);
  });
}
