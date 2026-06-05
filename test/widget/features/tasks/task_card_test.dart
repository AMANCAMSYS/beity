import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/tasks/domain/entities/task.dart';
import 'package:sawa/features/tasks/presentation/widgets/task_card.dart';

void main() {
  Widget buildCard({
    required Task task,
    required Future<void> Function() onComplete,
  }) {
    return ProviderScope(
      overrides: [
        appLocalizationsProvider.overrideWithValue(
          AppLocalizations(const Locale('en', 'US')),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            hapticsEnabled: false,
            soundsEnabled: false,
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'TaskCard clears optimistic completion when task identity changes',
    (tester) async {
      var completeCount = 0;
      const firstTask = Task(
        id: 'task-1',
        homeId: 'home-1',
        title: 'Buy rice',
        createdBy: 'user-1',
      );
      const nextTask = Task(
        id: 'task-2',
        homeId: 'home-1',
        title: 'Buy beans',
        createdBy: 'user-1',
      );

      await tester.pumpWidget(
        buildCard(task: firstTask, onComplete: () async => completeCount++),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

      await tester.pumpWidget(
        buildCard(task: nextTask, onComplete: () async => completeCount++),
      );

      expect(find.text('Buy beans'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await tester.pump(const Duration(milliseconds: 600));
      expect(completeCount, 0);
    },
  );
}
