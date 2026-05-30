import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../../activity_logs/presentation/utils/activity_localizer.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/beta_welcome_dialog.dart';
import '../../../onboarding/data/onboarding_storage.dart';
import '../../../onboarding/presentation/providers/app_tour_controller.dart';
import '../widgets/shopping_list_tile.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/app_drawer.dart';
import '../../../homes/presentation/screens/onboarding_screen.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_active_list_card.dart';
import '../widgets/home_header_sliver.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/core/services/startup_prefetch_provider.dart';
import 'package:beity/core/services/sync_coordinator.dart';
import 'package:beity/core/services/initial_data_hydration_service.dart';
import 'package:beity/features/offline_queue/presentation/providers/connectivity_provider.dart';
import '../../data/models/home_dashboard_snapshot.dart';
import '../../data/datasources/home_dashboard_snapshot_datasource.dart';
import '../providers/home_dashboard_snapshot_updater.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _tourScheduled = false;

  @override
  void initState() {
    super.initState();
    // Show beta welcome dialog on first launch
    if (BetaConfig.isBeta) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        BetaWelcomeDialog.showIfNeeded(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start progressive prefetching of all user data in the background (Phase 3)
    ref.watch(startupPrefetchProvider);

    // Watch hydration state
    final hydration = ref.watch(initialDataHydrationServiceProvider);

    if (hydration.status == HydrationStatus.hydratingHomes ||
        hydration.status == HydrationStatus.hydratingData) {
      final locale = Localizations.localeOf(context).languageCode;
      final titleText = locale == 'ar' ? 'جاري تجهيز بيانات منزلك...' : 'Preparing your home data...';
      final subtitleText = locale == 'ar'
          ? 'نعمل على مزامنة قوائمك وإعداداتك لتكون جاهزة للاستخدام فوراً.'
          : 'We are syncing your lists and settings to be ready immediately.';
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                AppSpacing.gapXL,
                Text(
                  titleText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapMD,
                Text(
                  subtitleText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (hydration.status == HydrationStatus.error) {
      final locale = Localizations.localeOf(context).languageCode;
      final errorTitle = locale == 'ar' ? 'فشلت المزامنة الأولية' : 'Initial sync failed';
      final errorSubtitle = locale == 'ar'
          ? 'يرجى التحقق من اتصال الشبكة وإعادة المحاولة.'
          : 'Please check your network connection and try again.';
      final retryText = locale == 'ar' ? 'إعادة المحاولة' : 'Retry';

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.signal_wifi_off_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                AppSpacing.gapXL,
                Text(
                  errorTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapMD,
                Text(
                  hydration.error ?? errorSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapXXL,
                BeityButton(
                  text: retryText,
                  onPressed: () {
                    ref.read(initialDataHydrationServiceProvider.notifier).hydrate(force: true);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 1. Synchronous reads for instant WhatsApp-like rendering (Phase 1 & 6)
    final homes = ref.watch(cachedUserHomesProvider);
    final activeHomeId = ref.watch(cachedActiveHomeIdProvider);
    final hasHomesAsync = ref.watch(hasHomesProvider);

    final hasHomes = hasHomesAsync.valueOrNull ?? true;

    // Trigger onboarding if initial sync completed and there are no homes
    if (hasHomesAsync.valueOrNull == false || (!hasHomes && homes.isEmpty)) {
      return const OnboardingScreen();
    }

    if (homes.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeHome = homes.firstWhere(
      (h) => h.id == activeHomeId,
      orElse: () => homes.first,
    );

    final homeId = activeHome.id;

    // Start background updater to compile snapshots when live data changes (Phase 5)
    ref.watch(homeDashboardSnapshotUpdaterProvider(homeId));

    // Schedule tour trigger after rendering
    if (!_tourScheduled && OnboardingStorage.shouldShowAppTour()) {
      _tourScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait briefly for animations/layout to settle
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            ref.read(appTourControllerProvider.notifier).maybeStartTour(context);
          }
        });
      });
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: _buildHomeContent(homeId, activeHome.name),
    );
  }

  Widget _buildHomeContent(String homeId, String homeName) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider(homeId));
    final snapshot = ref.watch(cachedHomeDashboardSnapshotProvider(homeId));
    final syncState = ref.watch(syncCoordinatorProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    final isOffline = connectivityAsync.valueOrNull?.isOffline ?? false;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        HomeHeaderSliver(homeId: homeId, homeName: homeName),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Sync Status Micro Bar (Phase 8) ──
              _buildSyncStatusBar(syncState, isOffline),

              // ── Quick actions ──
              HomeQuickActions(homeId: homeId),
              AppSpacing.gapXL,

              // ── Active list summary ──
              shoppingListsAsync.when(
                data: (lists) {
                  if (lists.isEmpty) return _buildEmptyListCard(homeId);
                  final activeList = lists.first;
                  return HomeActiveListCard(activeList: activeList);
                },
                loading: () {
                  // Fallback to cached dashboard snapshot for instant perceived loading
                  if (snapshot != null && snapshot.activeListId != null) {
                    return _buildActiveListSnapshotCard(snapshot);
                  }
                  return const BeityCard(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                },
                error: (e, _) {
                  if (snapshot != null && snapshot.activeListId != null) {
                    return _buildActiveListSnapshotCard(snapshot);
                  }
                  return BeityEmptyState(
                    title: context.translate('error_loading_lists'),
                    message: e.toString(),
                    icon: Icons.error_outline_rounded,
                    isError: true,
                    actionText: context.translate('retry'),
                    onAction: () => ref.invalidate(shoppingListsProvider(homeId)),
                  );
                },
              ),
              AppSpacing.gapXL,

              // ── All shopping lists ──
              shoppingListsAsync.when(
                data: (lists) {
                  if (lists.isEmpty) return const SizedBox.shrink();
                  return _buildShoppingListsSection(lists);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              AppSpacing.gapXL,

              // ── Recent activity ──
              _buildRecentActivity(homeId, snapshot),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Active list snapshot fallback card (Phase 4 & 6) ──────────────────────────────────────────
  Widget _buildActiveListSnapshotCard(HomeDashboardSnapshot snapshot) {
    final total = snapshot.totalShoppingItemsCount;
    final remaining = snapshot.remainingShoppingItemsCount;
    final progress = total > 0 ? (total - remaining) / total : 0.0;

    return BeityCard(
      onTap: () => context.push('/shopping-list/${snapshot.activeListId}'),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                AppSpacing.gapLG,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.activeListName ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        remaining == 0
                            ? context.translate('list_empty')
                            : context.translate('items_remaining_count', arguments: {
                                'remaining': remaining.toString(),
                                'total': total.toString(),
                              }),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            if (total > 0) ...[
              AppSpacing.gapLG,
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ],
            AppSpacing.gapLG,
            Row(
              children: [
                Expanded(
                  child: BeityButton(
                    onPressed: () => context.push('/shopping-list/${snapshot.activeListId}'),
                    text: context.translate('open_list'),
                    type: BeityButtonType.secondary,
                    icon: Icons.list_alt_rounded,
                  ),
                ),
                AppSpacing.gapMD,
                Expanded(
                  child: BeityButton(
                    onPressed: () {
                      context.push(
                        '/shopping-list/${snapshot.activeListId}/shopping-mode',
                        extra: {
                          'homeId': snapshot.homeId,
                          'listName': snapshot.activeListName ?? '',
                        },
                      );
                    },
                    text: context.translate('shopping_mode'),
                    type: BeityButtonType.primary,
                    icon: Icons.shopping_bag_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sync Status Micro Bar Widget (Phase 8) ──────────────────────────────────────────
  Widget _buildSyncStatusBar(SyncState syncState, bool isOffline) {
    if (isOffline) {
      final locale = Localizations.localeOf(context).languageCode;
      final text = locale == 'ar'
          ? 'أنت تعمل دون اتصال، سيتم حفظ التغييرات ومزامنتها لاحقاً'
          : 'You are working offline. Changes will be synced later.';
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 18),
            AppSpacing.gapMD,
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (syncState.status == SyncStatus.syncing) {
      final locale = Localizations.localeOf(context).languageCode;
      final text = locale == 'ar' ? 'جاري تحديث البيانات...' : 'Updating data...';
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
            AppSpacing.gapMD,
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Shopping lists section ──────────────────────────────────────────
  Widget _buildShoppingListsSection(List<ShoppingListModel> lists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.translate('shopping_lists'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/shopping-lists'),
              child: Text(context.translate('view_all')),
            ),
          ],
        ),
        AppSpacing.gapSM,
        ...lists
            .take(5)
            .map(
              (list) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ShoppingListTile(
                  listId: list.id,
                  listName: list.name,
                  icon: list.icon,
                ),
              ),
            ),
      ],
    );
  }

  // ─── Empty list card ─────────────────────────────────────────────────
  Widget _buildEmptyListCard(String homeId) {
    return BeityEmptyState(
      title: context.translate('no_shopping_lists'),
      message: context.translate('no_shopping_lists_desc'),
      icon: Icons.shopping_cart_outlined,
      actionText: context.translate('create_list'),
      onAction: () => context.push('/shopping-lists/create', extra: homeId),
    );
  }

  // ─── Recent activity ─────────────────────────────────────────────────
  Widget _buildRecentActivity(String homeId, HomeDashboardSnapshot? snapshot) {
    final recentActivityAsync = ref.watch(recentHomeActivityProvider(homeId));

    return recentActivityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('recent_activity'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.gapLG,
              BeityEmptyState(
                title: context.translate('no_activities_yet'),
                message: context.translate('no_activities_desc'),
                icon: Icons.history_rounded,
              ),
            ],
          );
        }

        final localeCode = Localizations.localeOf(context).languageCode;

        return RecentActivityWidget(
          activities: activities
              .map(
                (a) => ActivityItem(
                  userName: a.actorName ?? context.translate('user_label'),
                  action: a.getLocalizedDescription(context).replaceAll(a.entityName ?? '', '').trim(),
                  itemName: a.entityName ?? '',
                  icon: _getActionIcon(a.action.value),
                  color: _getActionColor(a.action.value),
                  timeAgo: timeago.format(a.createdAt, locale: localeCode),
                ),
              )
              .toList(),
          onViewAll: () => context.push('/activity'),
        );
      },
      loading: () {
        if (snapshot != null && snapshot.lastActivityText != null) {
          return _buildRecentActivitySnapshotWidget(snapshot.lastActivityText!);
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (e, _) {
        if (snapshot != null && snapshot.lastActivityText != null) {
          return _buildRecentActivitySnapshotWidget(snapshot.lastActivityText!);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate('recent_activity'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.gapLG,
            BeityEmptyState(
              title: context.translate('error_loading_activities', arguments: {'error': e.toString()}),
              message: e.toString(),
              icon: Icons.error_outline_rounded,
              isError: true,
              actionText: context.translate('retry'),
              onAction: () => ref.invalidate(recentHomeActivityProvider(homeId)),
            ),
          ],
        );
      },
    );
  }

  // ─── Recent activity snapshot fallback widget (Phase 4 & 6) ──────────────────────────────────────────
  Widget _buildRecentActivitySnapshotWidget(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('recent_activity'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapLG,
        RecentActivityWidget(
          activities: [
            ActivityItem(
              userName: '',
              action: text,
              itemName: '',
              icon: Icons.history_rounded,
              color: AppColors.info,
              timeAgo: '',
            ),
          ],
          onViewAll: () => context.push('/activity'),
        ),
      ],
    );
  }

  IconData _getActionIcon(String? action) {
    switch (action) {
      case 'item_added':
        return Icons.add_circle_outline;
      case 'item_purchased':
        return Icons.check_circle_outline;
      case 'list_created':
        return Icons.create_outlined;
      case 'member_joined':
        return Icons.person_add_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActionColor(String? action) {
    switch (action) {
      case 'item_added':
        return AppColors.info;
      case 'item_purchased':
        return AppColors.success;
      case 'list_created':
        return AppColors.primary;
      case 'member_joined':
        return AppColors.warning;
      default:
        return AppColors.textSecondaryFor(Theme.of(context).brightness);
    }
  }
}
