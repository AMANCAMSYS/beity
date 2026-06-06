import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/billing/domain/entities/subscription_plan.dart';
import 'package:sawa/features/billing/presentation/providers/subscription_plans_provider.dart';

void main() {
  group('subscription plans', () {
    test('define free, monthly, and yearly packages', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final plans = container.read(subscriptionPlansProvider);

      expect(plans.map((plan) => plan.id), [
        'free',
        'plus_monthly',
        'plus_yearly',
      ]);
      expect(plans[0].tier, SubscriptionTier.free);
      expect(plans[1].billingCycle, BillingCycle.monthly);
      expect(plans[2].billingCycle, BillingCycle.yearly);
    });

    test(
      'keeps purchase integration disabled until payment setup is ready',
      () {
        final paidPlans = subscriptionPlans.where((plan) => plan.isPaid);

        expect(paidPlans.map((plan) => plan.storeProductId), [
          'sawa_plus_monthly',
          'sawa_plus_yearly',
        ]);
        expect(paidPlans.every((plan) => !plan.isAvailableForPurchase), isTrue);
        expect(subscriptionPlans.last.isRecommended, isTrue);
      },
    );

    test('current entitlement starts on free MVP-safe limits', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final entitlement = container.read(
        currentSubscriptionEntitlementProvider,
      );

      expect(entitlement.planId, 'free');
      expect(entitlement.isPlus, isFalse);
      expect(entitlement.canUseInventory, isFalse);
      expect(entitlement.canUseExpenses, isFalse);
      expect(entitlement.canUseTasks, isFalse);
      expect(entitlement.limits.maxHomes, 1);
      expect(entitlement.limits.maxActiveLists, 3);
    });

    test('plus limits are prepared for later feature gates', () {
      expect(plusPlanLimits.hasUnlimitedHomes, isTrue);
      expect(plusPlanLimits.hasUnlimitedActiveLists, isTrue);
      expect(plusPlanLimits.includesInventory, isTrue);
      expect(plusPlanLimits.includesExpenses, isTrue);
      expect(plusPlanLimits.includesTasks, isTrue);
      expect(plusPlanLimits.includesPrioritySupport, isTrue);
      expect(plusPlanLimits.aiSuggestionsPerMonth, 100);
    });
  });
}
