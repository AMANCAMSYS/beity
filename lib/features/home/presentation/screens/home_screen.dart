import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../notifications/presentation/widgets/notification_badge_widget.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/beta_welcome_dialog.dart';
import '../../../beta/presentation/feedback_bottom_sheet.dart';
import '../widgets/shopping_list_tile.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/home_selector_dropdown.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkHomes());
    // Show beta welcome dialog on first launch
    if (BetaConfig.isBeta) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        BetaWelcomeDialog.showIfNeeded(context);
      });
    }
  }

  Future<void> _checkHomes() async {
    final hasHomes = await ref.read(hasHomesProvider.future);
    if (!hasHomes && mounted) {
      context.go('/onboarding');
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء الخير';
  }

  String get _userName {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['full_name'] as String? ?? 'المستخدم';
  }

  @override
  Widget build(BuildContext context) {
    final hasHomesAsync = ref.watch(hasHomesProvider);
    final userHomesAsync = ref.watch(userHomesProvider);
    final activeHomeIdAsync = ref.watch(activeHomeIdProvider);

    return hasHomesAsync.when(
      data: (hasHomes) {
        if (!hasHomes) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return userHomesAsync.when(
          data: (homes) {
            if (homes.isEmpty) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final activeHomeId = activeHomeIdAsync.valueOrNull;
            final activeHome = homes.firstWhere(
              (h) => h.id == activeHomeId,
              orElse: () => homes.first,
            );

            final homeId = activeHome.id;

            return Scaffold(
              drawer: _buildDrawer(context),
              body: _buildBody(homeId, activeHome.name),
              bottomNavigationBar: _buildBottomNav(),
            );
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const Scaffold(body: Center(child: Text('خطأ'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(body: Center(child: Text('خطأ'))),
    );
  }

  Widget _buildBody(String homeId, String homeName) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(homeId, homeName);
      case 1:
        return _buildShoppingListsTab(homeId);
      case 2:
        return _buildShoppingTab(homeId);
      case 3:
        return _buildActivityTab(homeId);
      case 4:
        return _buildSettingsTab();
      default:
        return _buildHomeContent(homeId, homeName);
    }
  }

  // ─── HOME TAB ────────────────────────────────────────────────────────
  Widget _buildHomeContent(String homeId, String homeName) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider(homeId));

    return CustomScrollView(
      slivers: [
        _buildHeader(homeId, homeName),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Quick actions ──
              _buildQuickActions(homeId),
              const SizedBox(height: 24),

              // ── Active list summary ──
              shoppingListsAsync.when(
                data: (lists) {
                  if (lists.isEmpty) return _buildEmptyListCard(homeId);
                  final activeList = lists.first;
                  return _buildActiveListSummary(activeList);
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // ── All shopping lists ──
              shoppingListsAsync.when(
                data: (lists) {
                  if (lists.isEmpty) return const SizedBox.shrink();
                  return _buildShoppingListsSection(lists);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // ── Recent activity ──
              _buildRecentActivity(homeId),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Quick actions row ───────────────────────────────────────────────
  Widget _buildQuickActions(String homeId) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_shopping_cart,
            label: 'إضافة عنصر',
            color: Colors.blue,
            onTap: () {
              final listsAsync = ref.read(shoppingListsProvider(homeId));
              listsAsync.whenData((lists) {
                if (lists.isNotEmpty) {
                  context.push('/shopping-list/${lists.first.id}/add-item');
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.shopping_bag_outlined,
            label: 'وضع التسوق',
            color: Colors.green,
            onTap: () {
              final listsAsync = ref.read(shoppingListsProvider(homeId));
              listsAsync.whenData((lists) {
                if (lists.isNotEmpty) {
                  context.push('/shopping-list/${lists.first.id}/shopping-mode', extra: {
                    'homeId': lists.first.homeId,
                    'listName': lists.first.name,
                  });
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.add,
            label: 'قائمة جديدة',
            color: Colors.orange,
            onTap: () => context.push('/shopping-lists/create', extra: homeId),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Active list summary (compact) ───────────────────────────────────
  Widget _buildActiveListSummary(dynamic activeList) {
    final itemsAsync = ref.watch(shoppingItemsProvider(activeList.id));

    return itemsAsync.when(
      data: (items) {
        final total = items.length;
        final purchased = items.where((i) => i.isPurchased).length;
        final remaining = total - purchased;
        final progress = total > 0 ? purchased / total : 0.0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => context.push('/shopping-list/${activeList.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getIconData(activeList.icon),
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeList.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              total == 0
                                  ? 'قائمة فارغة'
                                  : '$remaining متبقي من $total',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress chip
                      if (total > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getProgressColor(progress).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: _getProgressColor(progress),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Progress bar
                  if (total > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(progress),
                        ),
                      ),
                    ),
                  ],
                  // Action buttons
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/shopping-list/${activeList.id}'),
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('فتح القائمة'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/shopping-list/${activeList.id}/shopping-mode', extra: {
                              'homeId': activeList.homeId,
                              'listName': activeList.name,
                            });
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                          label: const Text('وضع التسوق'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // ─── Shopping lists section ──────────────────────────────────────────
  Widget _buildShoppingListsSection(List<dynamic> lists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'قوائم المشتريات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...lists.take(5).map((list) => ShoppingListTile(
          listId: list.id,
          listName: list.name,
          icon: list.icon,
        )),
      ],
    );
  }

  // ─── Empty list card ─────────────────────────────────────────────────
  Widget _buildEmptyListCard(String homeId) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'لا توجد قوائم مشتريات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أنشئ قائمتك الأولى لتبدأ',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/shopping-lists/create', extra: homeId),
              icon: const Icon(Icons.add),
              label: const Text('إنشاء قائمة'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recent activity ─────────────────────────────────────────────────
  Widget _buildRecentActivity(String homeId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('activity_logs')
          .select()
          .eq('home_id', homeId)
          .order('created_at', ascending: false)
          .limit(5)
          .then((response) => List<Map<String, dynamic>>.from(response)),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'آخر النشاطات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد نشاطات بعد',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return RecentActivityWidget(
          activities: activities.map((a) => ActivityItem(
            userName: a['actor_name'] ?? 'مستخدم',
            action: _getActionText(a['action']),
            itemName: a['entity_name'] ?? '',
            icon: _getActionIcon(a['action']),
            color: _getActionColor(a['action']),
            timeAgo: _getTimeAgo(a['created_at']),
          )).toList(),
          onViewAll: () => setState(() => _currentIndex = 3),
        );
      },
    );
  }

  // ─── Helper methods ──────────────────────────────────────────────────
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart': return Icons.shopping_cart;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'local_pharmacy': return Icons.local_pharmacy;
      case 'local_hospital': return Icons.local_hospital;
      case 'restaurant': return Icons.restaurant;
      case 'local_cafe': return Icons.local_cafe;
      case 'home': return Icons.home;
      case 'hardware': return Icons.hardware;
      case 'build': return Icons.build;
      case 'child_care': return Icons.child_care;
      case 'pets': return Icons.pets;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'celebration': return Icons.celebration;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'local_florist': return Icons.local_florist;
      default: return Icons.shopping_cart;
    }
  }

  String _getActionText(String? action) {
    switch (action) {
      case 'item_added': return 'أضاف';
      case 'item_purchased': return 'اشترى';
      case 'list_created': return 'أنشأ';
      case 'member_joined': return 'انضم';
      default: return 'قام بإجراء';
    }
  }

  IconData _getActionIcon(String? action) {
    switch (action) {
      case 'item_added': return Icons.add_circle_outline;
      case 'item_purchased': return Icons.check_circle_outline;
      case 'list_created': return Icons.create_outlined;
      case 'member_joined': return Icons.person_add_outlined;
      default: return Icons.info_outline;
    }
  }

  Color _getActionColor(String? action) {
    switch (action) {
      case 'item_added': return Colors.blue;
      case 'item_purchased': return Colors.green;
      case 'list_created': return Colors.purple;
      case 'member_joined': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }

  // ─── HEADER ──────────────────────────────────────────────────────────
  Widget _buildHeader(String homeId, String homeName) {
    final userHomesAsync = ref.watch(userHomesProvider);

    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_greeting، $_userName',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 2),
          userHomesAsync.when(
            data: (homes) => HomeSelectorDropdown(
              currentHomeName: homeName,
              homes: homes.map((h) => HomeOption(
                id: h.id,
                name: h.name,
                memberCount: 0,
                isActive: h.id == homeId,
              )).toList(),
              onHomeSelected: (selectedHomeId) {
                final selectedHome = homes.firstWhere((h) => h.id == selectedHomeId);
                ref.read(homeLocalDataSourceProvider).setActiveHome(selectedHomeId, selectedHome.name);
                ref.invalidate(activeHomeIdProvider);
              },
              onManageHomes: () => context.push('/homes'),
            ),
            loading: () => Text(homeName, style: const TextStyle(fontSize: 13)),
            error: (_, _) => Text(homeName, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
      actions: [
        NotificationBadgeWidget(
          onTap: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () => context.push('/profile'),
        ),
      ],
    );
  }

  // ─── DRAWER ──────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ?? 'المستخدم';
    final userEmail = user?.email ?? '';

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
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(userEmail, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _drawerItem(Icons.home, 'الرئيسية', 0),
          _drawerItem(Icons.list_alt, 'قوائم المشتريات', 1),
          _drawerItem(Icons.shopping_cart, 'وضع التسوق', 2),
          _drawerItem(Icons.history, 'النشاطات', 3),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('إدارة الأعضاء', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pop(context);
              final activeHomeId = ref.read(activeHomeIdProvider).valueOrNull;
              if (activeHomeId != null) context.push('/homes/$activeHomeId/members');
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('الدعوات', textDirection: TextDirection.rtl),
            onTap: () { Navigator.pop(context); context.push('/invitations'); },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('مركز الإشعارات', textDirection: TextDirection.rtl),
            onTap: () { Navigator.pop(context); context.push('/notifications'); },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('التصنيفات', textDirection: TextDirection.rtl),
            onTap: () { Navigator.pop(context); context.push('/categories'); },
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('وحدات القياس', textDirection: TextDirection.rtl),
            onTap: () { Navigator.pop(context); context.push('/units'); },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('إعدادات الإشعارات', textDirection: TextDirection.rtl),
            onTap: () { Navigator.pop(context); context.push('/notifications/preferences'); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('إدارة المنازل', textDirection: TextDirection.rtl),
            onTap: () { Navigator.pop(context); context.push('/homes'); },
          ),
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
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل تسجيل الخروج: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, textDirection: TextDirection.rtl),
      selected: _currentIndex == index,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = index);
      },
    );
  }

  // ─── SHOPPING LISTS TAB ──────────────────────────────────────────────
  Widget _buildShoppingListsTab(String homeId) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider(homeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('قوائم المشتريات'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: shoppingListsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('لا توجد قوائم', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('أنشئ قائمتك الأولى', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/shopping-lists/create', extra: homeId),
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء قائمة'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return ShoppingListTile(listId: list.id, listName: list.name, icon: list.icon);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/shopping-lists/create', extra: homeId),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ─── SHOPPING MODE TAB ───────────────────────────────────────────────
  Widget _buildShoppingTab(String homeId) {
    final listsAsync = ref.watch(shoppingListsProvider(homeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('وضع التسوق'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('لا توجد قوائم', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('أنشئ قائمة تسوق أولاً', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.green),
                  ),
                  title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/shopping-list/${list.id}/shopping-mode', extra: {
                      'homeId': list.homeId,
                      'listName': list.name,
                    });
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطأ في تحميل القوائم')),
      ),
    );
  }

  // ─── ACTIVITY TAB ────────────────────────────────────────────────────
  Widget _buildActivityTab(String homeId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النشاطات'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('activity_logs')
            .select()
            .eq('home_id', homeId)
            .order('created_at', ascending: false)
            .limit(50)
            .then((response) => List<Map<String, dynamic>>.from(response)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('لا توجد نشاطات', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActionColor(activity['action']).withValues(alpha: 0.1),
                    child: Icon(_getActionIcon(activity['action']), color: _getActionColor(activity['action']), size: 20),
                  ),
                  title: RichText(
                    textDirection: TextDirection.rtl,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: activity['actor_name'] ?? 'مستخدم',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${_getActionText(activity['action'])} '),
                        TextSpan(
                          text: '"${activity['entity_name'] ?? ''}"',
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Text(_getTimeAgo(activity['created_at'])),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── SETTINGS TAB ────────────────────────────────────────────────────
  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _settingsItem(Icons.person, 'الملف الشخصي', () => context.push('/profile')),
                _settingsItem(Icons.home, 'إدارة المنازل', () => context.push('/homes')),
                _settingsItem(Icons.category, 'التصنيفات', () => context.push('/categories')),
                _settingsItem(Icons.straighten, 'وحدات القياس', () => context.push('/units')),
                _settingsItem(Icons.notifications, 'إعدادات الإشعارات', () => context.push('/notifications/preferences')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.red)),
              onTap: () async {
                try {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل تسجيل الخروج: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsItem(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(label, textDirection: TextDirection.rtl),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }

  // ─── BOTTOM NAV ──────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'القوائم'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'التسوق'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'النشاط'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
      ],
    );
  }
}
