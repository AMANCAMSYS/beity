import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/notification_preferences_provider.dart';
import '../widgets/notification_preference_toggle.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeHomeId = ref.watch(cachedActiveHomeIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.translate('notification_settings'))),
      body: activeHomeId == null || activeHomeId.isEmpty
          ? _buildNoHomeState(context)
          : _buildPreferencesBody(context, ref),
    );
  }

  Widget _buildNoHomeState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.translate('no_active_home'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.translate('select_active_home_for_notifications'),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/homes'),
              icon: const Icon(Icons.home),
              label: Text(context.translate('select_home')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesBody(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return preferencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final message = error.toString();
        final isNoHome =
            message.contains('لا يوجد منزل نشط') ||
            message.contains('no_active_home') ||
            message.contains('no active home');

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNoHome ? Icons.home_outlined : Icons.error_outline,
                  size: 64,
                  color: isNoHome ? Colors.grey[400] : AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  isNoHome
                      ? context.translate('no_active_home')
                      : context.translate('failed_load_notifications'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isNoHome
                      ? context.translate(
                          'select_active_home_for_notifications',
                        )
                      : context.translate('unexpected_error_retry'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isNoHome)
                  ElevatedButton.icon(
                    onPressed: () => context.push('/homes'),
                    icon: const Icon(Icons.home),
                    label: Text(context.translate('select_home')),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(notificationPreferencesProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(context.translate('retry')),
                  ),
              ],
            ),
          ),
        );
      },
      data: (prefs) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.translate('notification_categories'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.translate('notification_categories_desc'),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            NotificationPreferenceToggle(
              label: context.translate('pref_item_added'),
              description: context.translate('pref_item_added_desc'),
              icon: Icons.add_circle_outline,
              value: prefs.itemAdded,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('item_added', v),
            ),
            NotificationPreferenceToggle(
              label: context.translate('pref_item_completed'),
              description: context.translate('pref_item_completed_desc'),
              icon: Icons.check_circle_outline,
              value: prefs.itemCompleted,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('item_completed', v),
            ),
            NotificationPreferenceToggle(
              label: context.translate('pref_low_stock'),
              description: context.translate('pref_low_stock_desc'),
              icon: Icons.warning_amber_outlined,
              value: prefs.lowStock,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('low_stock', v),
            ),
            NotificationPreferenceToggle(
              label: context.translate('pref_expiry_alert'),
              description: context.translate('pref_expiry_alert_desc'),
              icon: Icons.event_busy,
              value: prefs.expiryAlert,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('expiry_alert', v),
            ),
            NotificationPreferenceToggle(
              label: context.translate('pref_expense_added'),
              description: context.translate('pref_expense_added_desc'),
              icon: Icons.attach_money,
              value: prefs.expenseAdded,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('expense_added', v),
            ),
            NotificationPreferenceToggle(
              label: context.translate('pref_task_assigned'),
              description: context.translate('pref_task_assigned_desc'),
              icon: Icons.assignment_ind_outlined,
              value: prefs.taskAssigned,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('task_assigned', v),
            ),
            NotificationPreferenceToggle(
              label: context.translate('pref_task_due'),
              description: context.translate('pref_task_due_desc'),
              icon: Icons.schedule,
              value: prefs.taskDue,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('task_due', v),
            ),
          ],
        );
      },
    );
  }
}
