import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/notification_preferences_provider.dart';
import '../widgets/notification_preference_toggle.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeHomeId = ref.watch(activeHomeIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات'),
      ),
      body: activeHomeId.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildNoHomeState(context),
        data: (homeId) {
          if (homeId == null || homeId.isEmpty) {
            return _buildNoHomeState(context);
          }
          return _buildPreferencesBody(context, ref);
        },
      ),
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
            const Text(
              'لا يوجد منزل نشط',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى اختيار منزل أولًا لتعديل إعدادات الإشعارات.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/homes'),
              icon: const Icon(Icons.home),
              label: const Text('اختيار منزل'),
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
        final isNoHome = message.contains('لا يوجد منزل نشط');

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNoHome ? Icons.home_outlined : Icons.error_outline,
                  size: 64,
                  color: isNoHome ? Colors.grey[400] : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isNoHome ? 'لا يوجد منزل نشط' : 'تعذّر تحميل إعدادات الإشعارات',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  isNoHome
                      ? 'يرجى اختيار منزل أولًا لتعديل إعدادات الإشعارات.'
                      : 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isNoHome)
                  ElevatedButton.icon(
                    onPressed: () => context.push('/homes'),
                    icon: const Icon(Icons.home),
                    label: const Text('اختيار منزل'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(notificationPreferencesProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
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
              'فئات الإشعارات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر أنواع الإشعارات التي تريد استلامها.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            NotificationPreferenceToggle(
              label: 'إضافة صنف',
              description: 'إشعار عند إضافة أصناف جديدة للقوائم',
              icon: Icons.add_circle_outline,
              value: prefs.itemAdded,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('item_added', v),
            ),
            NotificationPreferenceToggle(
              label: 'إكمال صنف',
              description: 'إشعار عند إكمال أصناف من القوائم',
              icon: Icons.check_circle_outline,
              value: prefs.itemCompleted,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('item_completed', v),
            ),
            NotificationPreferenceToggle(
              label: 'مخزون منخفض',
              description: 'إشعار عند انخفاض المخزون',
              icon: Icons.warning_amber_outlined,
              value: prefs.lowStock,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('low_stock', v),
            ),
            NotificationPreferenceToggle(
              label: 'تنبيه انتهاء الصلاحية',
              description: 'إشعار عند اقتراب انتهاء صلاحية المنتجات',
              icon: Icons.event_busy,
              value: prefs.expiryAlert,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('expiry_alert', v),
            ),
            NotificationPreferenceToggle(
              label: 'إضافة مصروف',
              description: 'إشعار عند إضافة مصروفات جديدة',
              icon: Icons.attach_money,
              value: prefs.expenseAdded,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .updateField('expense_added', v),
            ),
            NotificationPreferenceToggle(
              label: 'موعد المهمة',
              description: 'تذكير بمواعيد المهام المستحقة',
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
