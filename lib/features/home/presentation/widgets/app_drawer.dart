import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/feedback_bottom_sheet.dart';
import 'package:beity/features/ai_suggestions/presentation/widgets/ai_list_selector_sheet.dart';
import '../../../../core/config/feature_flags.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ?? 'المستخدم';
    final userEmail = user?.email ?? '';
    final activeHomeId = ref.read(activeHomeIdProvider).valueOrNull;
    final homeId = activeHomeId ?? ref.read(userHomesProvider).valueOrNull?.firstOrNull?.id;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(userEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          // ── قسم المنزل ──
          _buildSectionHeader('المنزل'),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('إدارة المنازل', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/homes');
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('إدارة الأعضاء', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              if (homeId != null) {
                context.push('/homes/$homeId/members');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('الدعوات', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/invitations');
            },
          ),

          // ── قسم التسوق ──
          _buildSectionHeader('التسوق'),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('قوائم التسوق', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/shopping-lists');
            },
          ),
          if (FeatureFlags.enableInventory)
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('المخزون', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                context.push('/inventory');
              },
            ),
          if (FeatureFlags.enableAi)
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.accent),
              title: const Text('المساعد الذكي', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                if (homeId != null) {
                  AiListSelectorSheet.show(context, homeId);
                }
              },
            ),

          // ── قسم المالية ──
          if (FeatureFlags.enableExpenses) ...[
            _buildSectionHeader('المالية'),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('المصروفات', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('ملخص المصروفات', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses/summary');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('الأرصدة', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses/balances');
              },
            ),
          ],

          // ── قسم المهام ──
          if (FeatureFlags.enableTasks) ...[
            _buildSectionHeader('المهام'),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('المهام', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                context.push('/home/${homeId ?? ""}/tasks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('المهام المؤرشفة', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                context.push('/home/${homeId ?? ""}/tasks/archived');
              },
            ),
          ],

          // ── قسم النشاط ──
          _buildSectionHeader('النشاط'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('سجل النشاط', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/activity');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('مركز الإشعارات', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/notifications');
            },
          ),

          // ── قسم الإعدادات ──
          _buildSectionHeader('الإعدادات'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('الملف الشخصي', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('التصنيفات', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/categories');
            },
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('وحدات القياس', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/units');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('إعدادات الإشعارات', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              context.push('/notifications/preferences');
            },
          ),

          // ── قسم أخرى ──
          const Divider(),
          if (BetaConfig.isBeta)
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('إرسال ملاحظات', textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                FeedbackBottomSheet.show(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('تسجيل الخروج',
                textDirection: TextDirection.rtl,
                style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل تسجيل الخروج: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 16, bottom: 4),
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
