import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/core/localization/app_localizations.dart';
import '../providers/homes_provider.dart';
import '../widgets/home_card_widget.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../notifications/presentation/providers/unread_count_provider.dart';
import '../../../notifications/presentation/providers/notification_preferences_provider.dart';
import '../../../tasks/presentation/providers/task_filter_providers.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';

class HomesListScreen extends ConsumerStatefulWidget {
  const HomesListScreen({super.key});

  @override
  ConsumerState<HomesListScreen> createState() => _HomesListScreenState();
}

class _HomesListScreenState extends ConsumerState<HomesListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homesNotifierProvider.notifier).loadHomes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homesAsync = ref.watch(homesNotifierProvider);
    final activeHomeId = ref.watch(cachedActiveHomeIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('homes')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(homesNotifierProvider.notifier).refreshHomes(),
            tooltip: context.translate('refresh_list'),
          ),
        ],
      ),
      body: homesAsync.when(
        data: (homes) {
          if (homes.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(homesNotifierProvider.notifier).refreshHomes();
            },
            color: theme.colorScheme.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: homes.length,
              itemBuilder: (context, index) {
                final home = homes[index];
                final isActive = home.id == activeHomeId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: HomeCardWidget(
                    home: home,
                    isActive: isActive,
                    onTap: () async {
                      final localDataSource = ref.read(homeLocalDataSourceProvider);
                      await localDataSource.setActiveHome(home.id, home.name);
                      ref.invalidate(activeHomeIdProvider);
                      // Invalidate home-scoped providers to refresh for new home
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                      ref.invalidate(notificationPreferencesProvider);
                      ref.invalidate(taskFilterProvider);
                      ref.invalidate(activityFilterProvider);
                      ref.invalidate(categoryNotifierProvider);
                      ref.invalidate(unitNotifierProvider);
                      if (context.mounted) {
                        BeitySnackBar.success(
                          context,
                          context.translate('home_switched_success', arguments: {'name': home.name}),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => BeityEmptyState(
          title: context.translate('error_occurred'),
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.read(homesNotifierProvider.notifier).loadHomes(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/homes/create'),
        label: Text(context.translate('new_home')),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return BeityEmptyState(
      title: context.translate('no_homes_yet'),
      message: context.translate('create_first_home_guideline'),
      icon: Icons.home_outlined,
      actionText: context.translate('create_first_home'),
      onAction: () => context.push('/homes/create'),
    );
  }
}
