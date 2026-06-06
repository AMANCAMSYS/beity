import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_plan.dart';

const freePlanLimits = PlanLimits(
  maxHomes: 1,
  maxMembersPerHome: 2,
  maxActiveLists: 3,
  aiSuggestionsPerMonth: 5,
  includesInventory: false,
  includesExpenses: false,
  includesTasks: false,
  includesPrioritySupport: false,
);

const plusPlanLimits = PlanLimits(
  maxHomes: -1,
  maxMembersPerHome: 8,
  maxActiveLists: -1,
  aiSuggestionsPerMonth: 100,
  includesInventory: true,
  includesExpenses: true,
  includesTasks: true,
  includesPrioritySupport: true,
);

const subscriptionPlans = [
  SubscriptionPlan(
    id: 'free',
    storeProductId: null,
    tier: SubscriptionTier.free,
    billingCycle: BillingCycle.free,
    titleKey: 'plan_free_title',
    subtitleKey: 'plan_free_subtitle',
    priceLabelKey: 'plan_free_price',
    featureKeys: [
      'plan_feature_core_shopping',
      'plan_feature_one_home',
      'plan_feature_basic_ai',
    ],
    limits: freePlanLimits,
  ),
  SubscriptionPlan(
    id: 'plus_monthly',
    storeProductId: 'sawa_plus_monthly',
    tier: SubscriptionTier.plus,
    billingCycle: BillingCycle.monthly,
    titleKey: 'plan_plus_monthly_title',
    subtitleKey: 'plan_plus_monthly_subtitle',
    priceLabelKey: 'plan_price_pending_monthly',
    featureKeys: [
      'plan_feature_unlimited_lists',
      'plan_feature_family_members',
      'plan_feature_inventory_expenses_tasks',
      'plan_feature_ai_quota',
      'plan_feature_priority_support',
    ],
    limits: plusPlanLimits,
  ),
  SubscriptionPlan(
    id: 'plus_yearly',
    storeProductId: 'sawa_plus_yearly',
    tier: SubscriptionTier.plus,
    billingCycle: BillingCycle.yearly,
    titleKey: 'plan_plus_yearly_title',
    subtitleKey: 'plan_plus_yearly_subtitle',
    priceLabelKey: 'plan_price_pending_yearly',
    badgeKey: 'plan_badge_best_value',
    featureKeys: [
      'plan_feature_unlimited_lists',
      'plan_feature_family_members',
      'plan_feature_inventory_expenses_tasks',
      'plan_feature_ai_quota',
      'plan_feature_priority_support',
      'plan_feature_yearly_savings',
    ],
    limits: plusPlanLimits,
    isRecommended: true,
  ),
];

final subscriptionPlansProvider = Provider<List<SubscriptionPlan>>((ref) {
  return subscriptionPlans;
});

final currentSubscriptionEntitlementProvider =
    Provider<SubscriptionEntitlement>((ref) {
      return const SubscriptionEntitlement(
        tier: SubscriptionTier.free,
        planId: 'free',
        limits: freePlanLimits,
      );
    });
