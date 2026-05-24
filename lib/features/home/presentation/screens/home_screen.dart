import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../invitations/presentation/providers/invitations_provider.dart';
import '../../../invitations/presentation/widgets/invitation_card_widget.dart';
import '../../../notifications/presentation/widgets/notification_badge_widget.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../notifications/presentation/providers/unread_count_provider.dart';
import '../../../notifications/presentation/providers/notification_preferences_provider.dart';
import '../../../tasks/presentation/providers/task_filter_providers.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../beta/data/beta_config.dart';
import '../../../beta/presentation/beta_welcome_dialog.dart';
import '../widgets/shopping_list_tile.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/home_selector_dropdown.dart';
import '../widgets/app_drawer.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/features/ai_suggestions/presentation/widgets/ai_list_selector_sheet.dart';
import '../../../../core/config/feature_flags.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء الخير';
  }

  String get _userName {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return user?.email ?? 'المستخدم';
  }

  @override
  Widget build(BuildContext context) {
    final hasHomesAsync = ref.watch(hasHomesProvider);
    final userHomesAsync = ref.watch(userHomesProvider);
    final activeHomeIdAsync = ref.watch(activeHomeIdProvider);

    return hasHomesAsync.when(
      data: (hasHomes) {
        if (!hasHomes) {
          final invitationsAsync = ref.watch(userInvitationsStreamProvider);
          return Scaffold(
            appBar: AppBar(
              title: const Text('بيتي', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                const NotificationBadgeWidget(),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.push('/profile'),
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome card
                    BeityCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.home_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مرحباً بك في بيتي 👋',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _userName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'أنت لست عضواً في أي منزل بعد. للبدء، يمكنك إنشاء منزل جديد أو الانضمام إلى منزل عبر الدعوات الواردة إليك.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: BeityButton(
                              onPressed: () => context.push('/homes/create'),
                              text: 'إنشاء منزل جديد',
                              icon: Icons.add_home_outlined,
                              type: BeityButtonType.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Invitations Section
                    Text(
                      'الدعوات الواردة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    invitationsAsync.when(
                      data: (invitations) {
                        final pendingInvitations = invitations.where((inv) => inv.isPending).toList();
                        if (pendingInvitations.isEmpty) {
                          return BeityCard(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.mail_outline_rounded,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد دعوات معلقة حالياً',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingInvitations.length,
                          itemBuilder: (context, index) {
                            return InvitationCardWidget(
                              invitation: pendingInvitations[index],
                              isOwner: false,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => BeityCard(
                        child: Text(
                          'خطأ في تحميل الدعوات: $err',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
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
              drawer: const AppDrawer(),
              body: _buildHomeContent(homeId, activeHome.name),
            );
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            body: BeityEmptyState(
              title: 'خطأ في تحميل المنازل',
              message: e.toString(),
              icon: Icons.error_outline_rounded,
              isError: true,
              actionText: 'إعادة المحاولة',
              onActionPressed: () {
                ref.invalidate(userHomesProvider);
                ref.invalidate(hasHomesProvider);
              },
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: BeityEmptyState(
          title: 'خطأ في التحقق من الحساب',
          message: e.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: 'إعادة المحاولة',
          onActionPressed: () => ref.invalidate(hasHomesProvider),
        ),
      ),
    );
  }

  // ─── HOME CONTENT ────────────────────────────────────────────────────────
  Widget _buildHomeContent(String homeId, String homeName) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider(homeId));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader(homeId, homeName),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Quick actions ──
              _buildQuickActions(homeId),
              AppSpacing.gapXL,

              // ── Active list summary ──
              shoppingListsAsync.when(
                data: (lists) {
                  if (lists.isEmpty) return _buildEmptyListCard(homeId);
                  final activeList = lists.first;
                  return _buildActiveListSummary(activeList);
                },
                loading: () => const BeityCard(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => BeityEmptyState(
                  title: 'خطأ في تحميل القوائم',
                  message: e.toString(),
                  icon: Icons.error_outline_rounded,
                  isError: true,
                  actionText: 'إعادة المحاولة',
                  onActionPressed: () => ref.invalidate(shoppingListsProvider(homeId)),
                ),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_shopping_cart_rounded,
            label: 'إضافة عنصر',
            color: theme.colorScheme.primary,
            onTap: () {
              final listsAsync = ref.read(shoppingListsProvider(homeId));
              listsAsync.whenData((lists) {
                if (lists.isNotEmpty) {
                  context.push('/shopping-list/${lists.first.id}/add-item');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('يجب إنشاء قائمة تسوق أولاً', textDirection: TextDirection.rtl),
                      backgroundColor: theme.colorScheme.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
          ),
        ),
        AppSpacing.gapMD,
        Expanded(
          child: _buildActionCard(
            icon: Icons.shopping_bag_rounded,
            label: 'وضع التسوق',
            color: theme.colorScheme.tertiary,
            onTap: () {
              final listsAsync = ref.read(shoppingListsProvider(homeId));
              listsAsync.whenData((lists) {
                if (lists.isNotEmpty) {
                  context.push('/shopping-list/${lists.first.id}/shopping-mode', extra: {
                    'homeId': lists.first.homeId,
                    'listName': lists.first.name,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('لا توجد قوائم تسوق لتفعيل وضع التسوق', textDirection: TextDirection.rtl),
                      backgroundColor: theme.colorScheme.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
          ),
        ),
        if (FeatureFlags.enableAi) ...[
          AppSpacing.gapMD,
          Expanded(
            child: _buildActionCard(
              icon: Icons.auto_awesome_rounded,
              label: 'اقتراحات ذكية',
              color: Colors.amber,
              onTap: () => AiListSelectorSheet.show(context, homeId),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return BeityCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            AppSpacing.gapSM,
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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

        return BeityCard(
          onTap: () => context.push('/shopping-list/${activeList.id}'),
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        _getIconData(activeList.icon),
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
                            activeList.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            total == 0
                                ? 'قائمة فارغة'
                                : '$remaining متبقي من $total',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress chip
                    if (total > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: _getProgressColor(progress).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: _getProgressColor(progress),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                // Progress bar
                if (total > 0) ...[
                  AppSpacing.gapLG,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: _getProgressColor(progress).withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                ],
                // Action buttons
                AppSpacing.gapLG,
                Row(
                  children: [
                    Expanded(
                      child: BeityButton(
                        onPressed: () => context.push('/shopping-list/${activeList.id}'),
                        text: 'فتح القائمة',
                        type: BeityButtonType.secondary,
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    AppSpacing.gapMD,
                    Expanded(
                      child: BeityButton(
                        onPressed: () {
                          context.push('/shopping-list/${activeList.id}/shopping-mode', extra: {
                            'homeId': activeList.homeId,
                            'listName': activeList.name,
                          });
                        },
                        text: 'وضع التسوق',
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/shopping-lists'),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        AppSpacing.gapSM,
        ...lists.take(5).map((list) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ShoppingListTile(
            listId: list.id,
            listName: list.name,
            icon: list.icon,
          ),
        )),
      ],
    );
  }

  // ─── Empty list card ─────────────────────────────────────────────────
  Widget _buildEmptyListCard(String homeId) {
    return BeityEmptyState(
      title: 'لا توجد قوائم مشتريات',
      message: 'أنشئ قائمتك الأولى لتبدأ بتنظيم مشترياتك',
      icon: Icons.shopping_cart_outlined,
      actionText: 'إنشاء قائمة',
      onActionPressed: () => context.push('/shopping-lists/create', extra: homeId),
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
              Text(
                'آخر النشاطات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapLG,
              BeityEmptyState(
                title: 'لا توجد نشاطات بعد',
                message: 'ستظهر هنا آخر التحديثات من أفراد منزلك',
                icon: Icons.history_rounded,
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
          onViewAll: () => context.push('/activity'),
        );
      },
    );
  }

  // ─── Helper methods ──────────────────────────────────────────────────
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return const Color(0xFF66BB6A); // Modern soft emerald green
    if (progress >= 0.5) return const Color(0xFF42A5F5); // Modern soft cyan blue
    if (progress >= 0.3) return const Color(0xFFFFA726); // Modern warm amber
    return const Color(0xFFEF5350); // Modern soft coral red
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'local_grocery_store': return Icons.local_grocery_store_rounded;
      case 'local_pharmacy': return Icons.local_pharmacy_rounded;
      case 'local_hospital': return Icons.local_hospital_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'local_cafe': return Icons.local_cafe_rounded;
      case 'home': return Icons.home_rounded;
      case 'hardware': return Icons.hardware_rounded;
      case 'build': return Icons.build_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'pets': return Icons.pets_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      case 'celebration': return Icons.celebration_rounded;
      case 'school': return Icons.school_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'cleaning_services': return Icons.cleaning_services_rounded;
      case 'local_florist': return Icons.local_florist_rounded;
      default: return Icons.shopping_cart_rounded;
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
    final theme = Theme.of(context);

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_greeting، $_userName',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
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
            ),
            loading: () => Text(
              homeName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            error: (_, _) => Text(
              homeName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (FeatureFlags.enableAi)
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
            onPressed: () => AiListSelectorSheet.show(context, homeId),
            tooltip: 'المساعد الذكي',
          ),
        NotificationBadgeWidget(
          onTap: () => context.push('/notifications'),
        ),
        IconButton(
          icon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => context.push('/profile'),
        ),
        AppSpacing.gapSM,
      ],
    );
  }
}
