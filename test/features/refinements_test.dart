import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beity/features/ai_suggestions/domain/entities/ai_mode.dart';
import 'package:beity/features/ai_suggestions/presentation/widgets/ai_mode_selector.dart';
import 'package:beity/features/inventory/presentation/widgets/quantity_adjuster_widget.dart';
import 'package:beity/features/inventory/domain/entities/inventory_item.dart';
import 'package:beity/features/tasks/domain/entities/task.dart';
import 'package:beity/features/beta/presentation/feedback_bottom_sheet.dart';
import 'package:beity/features/settings/data/repositories/app_settings_repository.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';

void main() {
  group('Refinements - Quantity Adjuster Step Sizing', () {
    test('fractional units should return step size of 0.25', () {
      final adjusterKg = QuantityAdjusterWidget(
        quantity: 1.0,
        unitId: 'Kg', 
        onChanged: (_) {},
      );

      final adjusterLtr = QuantityAdjusterWidget(
        quantity: 1.0,
        unitId: 'كجم', 
        onChanged: (_) {},
      );

      final adjusterLiter = QuantityAdjusterWidget(
        quantity: 1.0,
        unitId: 'لتر', 
        onChanged: (_) {},
      );

      expect(adjusterKg.step, 0.25);
      expect(adjusterLtr.step, 0.25);
      expect(adjusterLiter.step, 0.25);
    });

    test('whole and other units should return step size of 1.0', () {
      final adjusterPiece = QuantityAdjusterWidget(
        quantity: 1.0,
        unitId: 'Piece', 
        onChanged: (_) {},
      );

      final adjusterBox = QuantityAdjusterWidget(
        quantity: 1.0,
        unitId: 'كرتون', 
        onChanged: (_) {},
      );

      final adjusterNull = QuantityAdjusterWidget(
        quantity: 1.0,
        unitId: null, 
        onChanged: (_) {},
      );

      expect(adjusterPiece.step, 1.0);
      expect(adjusterBox.step, 1.0);
      expect(adjusterNull.step, 1.0);
    });
  });

  group('Refinements - Inventory Low Stock logic', () {
    test('isLowStock returns true when quantity is <= minQuantity', () {
      const itemLow = InventoryItem(
        id: '1',
        homeId: 'home-1',
        name: 'Sugar',
        quantity: 1.0,
        minQuantity: 2.0,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );

      const itemEqual = InventoryItem(
        id: '2',
        homeId: 'home-1',
        name: 'Salt',
        quantity: 2.0,
        minQuantity: 2.0,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );

      expect(itemLow.isLowStock, isTrue);
      expect(itemEqual.isLowStock, isTrue);
      expect(itemLow.restockSuggestion, 3.0);
    });

    test('isLowStock returns false when quantity > minQuantity or minQuantity is null', () {
      const itemHigh = InventoryItem(
        id: '3',
        homeId: 'home-1',
        name: 'Sugar',
        quantity: 3.0,
        minQuantity: 2.0,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );

      const itemNull = InventoryItem(
        id: '4',
        homeId: 'home-1',
        name: 'Pepper',
        quantity: 1.0,
        minQuantity: null,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );

      expect(itemHigh.isLowStock, isFalse);
      expect(itemNull.isLowStock, isFalse);
      expect(itemNull.restockSuggestion, 0.0);
    });
  });

  group('Refinements - Task Due Date logic', () {
    test('Task dates getters work correctly', () {
      final today = DateTime.now();
      final past = today.subtract(const Duration(days: 2));

      final taskDueToday = Task(
        id: '1',
        homeId: 'home-1',
        title: 'Task Today',
        dueDate: today,
        createdBy: 'user-1',
      );

      final taskOverdue = Task(
        id: '2',
        homeId: 'home-1',
        title: 'Task Past',
        dueDate: past,
        createdBy: 'user-1',
      );

      expect(taskDueToday.isDueToday, isTrue);
      expect(taskOverdue.isOverdue, isTrue);
    });
  });

  group('Refinements - AI Portals and SubModes Mapping', () {
    test('AiPortal shopping submodes should map correctly', () {
      final subModes = AiPortal.shopping.subModes;
      expect(subModes, contains(AiMode.shoppingSuggestions));
      expect(subModes, contains(AiMode.ramadanList));
      expect(subModes, contains(AiMode.travelList));
      expect(subModes, contains(AiMode.cleaningList));
      expect(subModes.length, 4);
    });

    test('AiPortal cooking submodes should map correctly', () {
      final subModes = AiPortal.cooking.subModes;
      expect(subModes, contains(AiMode.whatToCook));
      expect(subModes, contains(AiMode.recipeIngredients));
      expect(subModes, contains(AiMode.cookByAvailable));
      expect(subModes, contains(AiMode.weeklyMealPlan));
    });

    test('AiPortal occasions submodes should map correctly', () {
      final subModes = AiPortal.occasions.subModes;
      expect(subModes, contains(AiMode.guestMeals));
      expect(subModes, contains(AiMode.kidsMeals));
      expect(subModes.length, 2);
    });

    test('AiPortal default modes should map correctly', () {
      expect(AiPortal.shopping.defaultMode, AiMode.shoppingSuggestions);
      expect(AiPortal.cooking.defaultMode, AiMode.whatToCook);
      expect(AiPortal.occasions.defaultMode, AiMode.guestMeals);
    });
  });

  group('Refinements - AI Mode Selector Widget', () {
    testWidgets('AiModeSelector renders portals and handles taps', (WidgetTester tester) async {
      AiMode? changedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiModeSelector(
              selectedMode: AiMode.shoppingSuggestions,
              onModeChanged: (mode) {
                changedMode = mode;
              },
            ),
          ),
        ),
      );

      // Verify portal labels/icons are rendered
      expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);

      // Tap on Cooking Portal card (What to Cook? / ماذا أطبخ؟)
      await tester.tap(find.byIcon(Icons.restaurant_menu_rounded));
      await tester.pumpAndSettle();

      // Verify that callback triggers default mode of cooking portal
      expect(changedMode, AiMode.whatToCook);
    });
  });

  group('Refinements - Feedback ScreenRoute Attachment', () {
    testWidgets('FeedbackBottomSheet registers and renders screenRoute name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Simulating manual injection of screenRoute name
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const FeedbackBottomSheet(screenRoute: '/inventory-details'),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Verify screenRoute text is visible
      expect(find.text('الشاشة الحالية: /inventory-details'), findsOneWidget);
    });
  });

  group('Refinements - Device Locale detection', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences.init();
    });

    test('getLocale returns saved locale if present in SharedPreferences', () async {
      await AppPreferences.instance.setString('settings.locale', 'tr');
      final repository = AppSettingsRepository();
      final locale = await repository.getLocale();
      expect(locale.languageCode, 'tr');
    });

    test('getLocale returns device locale if supported and no saved locale', () async {
      final repository = AppSettingsRepository();
      final locale = await repository.getLocale();
      // By default in test environment it should fall back to 'en'
      expect(locale.languageCode, 'en');
    });
  });
}
