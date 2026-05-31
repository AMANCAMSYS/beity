import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/sync_coordinator.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../onboarding/presentation/providers/app_tour_target_registry.dart';
import 'drawer_toggle_button.dart';
import 'home_selector_dropdown.dart';
import '../../../notifications/presentation/widgets/notification_badge_widget.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../notifications/presentation/providers/unread_count_provider.dart';
import '../../../notifications/presentation/providers/notification_preferences_provider.dart';
import '../../../tasks/presentation/providers/task_filter_providers.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../ai_suggestions/presentation/widgets/ai_list_selector_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeHeaderSliver extends ConsumerWidget {
  final String homeId;
  final String homeName;

  const HomeHeaderSliver({
    super.key,
    required this.homeId,
    required this.homeName,
  });

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.translate('good_morning');
    if (hour < 17) return context.translate('good_afternoon');
    return context.translate('good_evening');
  }

  String _getUserName(BuildContext context, WidgetRef ref) {
    final user = ref.watch(cachedCurrentUserProvider);
    if (user != null && user.fullName.isNotEmpty) return user.fullName;
    return user?.email ?? context.translate('user_label');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userHomes = ref.watch(cachedUserHomesProvider);
    final theme = Theme.of(context);

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 62,
      leading: Builder(builder: (context) => const DrawerToggleButton()),
      title: Column(
        key: AppTourTargetRegistry.homeHeaderKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_getGreeting(context)}، ${_getUserName(context, ref)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          userHomes.isNotEmpty
              ? HomeSelectorDropdown(
                  currentHomeName: homeName,
                  homes: userHomes
                      .map(
                        (h) => HomeOption(
                          id: h.id,
                          name: h.name,
                          memberCount: 0,
                          isActive: h.id == homeId,
                        ),
                      )
                      .toList(),
                  onHomeSelected: (selectedHomeId) {
                    final selectedHome = userHomes.firstWhere(
                      (h) => h.id == selectedHomeId,
                    );
                    ref
                        .read(homeLocalDataSourceProvider)
                        .setActiveHome(selectedHomeId, selectedHome.name);
                    ref.invalidate(activeHomeIdProvider);
                    // Invalidate home-scoped providers to refresh for new home
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                    ref.invalidate(notificationPreferencesProvider);
                    ref.invalidate(taskFilterProvider);
                    ref.invalidate(activityFilterProvider);
                    ref.invalidate(categoryNotifierProvider);
                    ref.invalidate(unitNotifierProvider);
                  },
                  onManageHomes: () => context.push('/homes'),
                )
              : Text(
                  homeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
          _buildSyncIndicator(context, ref, theme),
        ],
      ),
      actions: [
        if (FeatureFlags.enableAi)
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.accent,
            ),
            onPressed: () => AiListSelectorSheet.show(context, homeId),
            tooltip: context.translate('ai_assistant'),
          ),
        NotificationBadgeWidget(onTap: () => context.push('/notifications')),
        IconButton(
          icon: Icon(
            Icons.person_outline_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => context.push('/profile'),
        ),
        AppSpacing.gapSM,
      ],
    );
  }

  Widget _buildSyncIndicator(BuildContext context, WidgetRef ref, ThemeData theme) {
    final syncState = ref.watch(syncCoordinatorProvider);
    if (syncState.status == SyncStatus.idle || syncState.status == SyncStatus.success) {
      return const SizedBox.shrink();
    }

    Color color = theme.colorScheme.primary;
    String text = context.translate('syncing');
    IconData icon = Icons.sync_rounded;

    if (syncState.status == SyncStatus.partiallySynced) {
      color = Colors.orange;
      text = context.translate('partially_synced');
      icon = Icons.warning_amber_rounded;
    } else if (syncState.status == SyncStatus.error) {
      color = Colors.red;
      text = context.translate('sync_error');
      icon = Icons.cloud_off_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
