enum SubscriptionTier { free, plus }

enum BillingCycle { free, monthly, yearly }

class PlanLimits {
  final int maxHomes;
  final int maxMembersPerHome;
  final int maxActiveLists;
  final int aiSuggestionsPerMonth;
  final bool includesInventory;
  final bool includesExpenses;
  final bool includesTasks;
  final bool includesPrioritySupport;

  const PlanLimits({
    required this.maxHomes,
    required this.maxMembersPerHome,
    required this.maxActiveLists,
    required this.aiSuggestionsPerMonth,
    required this.includesInventory,
    required this.includesExpenses,
    required this.includesTasks,
    required this.includesPrioritySupport,
  });

  bool get hasUnlimitedHomes => maxHomes < 0;
  bool get hasUnlimitedActiveLists => maxActiveLists < 0;
}

class SubscriptionPlan {
  final String id;
  final String? storeProductId;
  final SubscriptionTier tier;
  final BillingCycle billingCycle;
  final String titleKey;
  final String subtitleKey;
  final String priceLabelKey;
  final String? badgeKey;
  final List<String> featureKeys;
  final PlanLimits limits;
  final bool isRecommended;
  final bool isAvailableForPurchase;

  const SubscriptionPlan({
    required this.id,
    required this.storeProductId,
    required this.tier,
    required this.billingCycle,
    required this.titleKey,
    required this.subtitleKey,
    required this.priceLabelKey,
    required this.featureKeys,
    required this.limits,
    this.badgeKey,
    this.isRecommended = false,
    this.isAvailableForPurchase = false,
  });

  bool get isPaid => tier != SubscriptionTier.free;
  bool get isYearly => billingCycle == BillingCycle.yearly;
}

class SubscriptionEntitlement {
  final SubscriptionTier tier;
  final String planId;
  final PlanLimits limits;
  final DateTime? expiresAt;

  const SubscriptionEntitlement({
    required this.tier,
    required this.planId,
    required this.limits,
    this.expiresAt,
  });

  bool get isPlus => tier == SubscriptionTier.plus;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canUseInventory => limits.includesInventory;
  bool get canUseExpenses => limits.includesExpenses;
  bool get canUseTasks => limits.includesTasks;
  bool get canUseAiSuggestions => limits.aiSuggestionsPerMonth != 0;
}
