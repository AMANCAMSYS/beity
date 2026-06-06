import 'dart:ui';
import 'package:sawa/app/router/shopping_route_paths.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/core/config/feature_flags.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/ai_suggestions/presentation/widgets/ai_list_selector_sheet.dart';
import 'package:sawa/features/beta/data/beta_config.dart';
import 'package:sawa/features/beta/presentation/feedback_bottom_sheet.dart';
import 'package:sawa/features/auth/presentation/providers/auth_provider.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = SupabaseService.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ?? '';
    final userEmail = user?.email ?? '';
    final activeHomeId = ref.watch(cachedActiveHomeIdProvider);
    final homes = ref.watch(cachedUserHomesProvider);
    final homeId = activeHomeId ?? homes.firstOrNull?.id;
    final path = GoRouterState.of(context).uri.path;
    final hasHome = homeId != null && homeId.isNotEmpty;
    final homeName = homes.where((h) => h.id == homeId).firstOrNull?.name;

    final surface = isDark
        ? const Color(0xFF0F0F1A).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.06,
    );

    return Drawer(
      width: 260,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Header ──
                  _header(context, theme, userName, userEmail, homeName),
                  // ── List ──
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      children: [
                        _label(
                          context,
                          context.translate('drawer_section_main'),
                        ),
                        _item(
                          context,
                          theme,
                          Icons.home_rounded,
                          context.translate('home_tab'),
                          path == '/',
                          () => _go(context, '/'),
                        ),
                        _item(
                          context,
                          theme,
                          Icons.shopping_cart_rounded,
                          context.translate('shopping_lists'),
                          path.startsWith(ShoppingRoutePaths.detailPrefix),
                          () => _go(context, ShoppingRoutePaths.lists),
                          enabled: hasHome,
                        ),
                        _item(
                          context,
                          theme,
                          Icons.shopping_bag_rounded,
                          context.translate('shopping_mode'),
                          path == ShoppingRoutePaths.mode,
                          () => _go(context, ShoppingRoutePaths.mode),
                          enabled: hasHome,
                        ),
                        _item(
                          context,
                          theme,
                          Icons.history_rounded,
                          context.translate('activity_tab'),
                          path.startsWith('/activity'),
                          () => _go(context, '/activity'),
                          enabled: hasHome,
                        ),
                        _sep(context),
                        _label(
                          context,
                          context.translate('drawer_section_home'),
                        ),
                        _item(
                          context,
                          theme,
                          Icons.home_work_rounded,
                          context.translate('homes'),
                          path.startsWith('/homes'),
                          () => _push(context, '/homes'),
                        ),
                        _item(
                          context,
                          theme,
                          Icons.group_rounded,
                          context.translate('home_members'),
                          path.contains('/members'),
                          () => _push(context, '/homes/$homeId/members'),
                          enabled: hasHome,
                        ),
                        _item(
                          context,
                          theme,
                          Icons.mail_rounded,
                          context.translate('invitations'),
                          path.startsWith('/invitations'),
                          () => _push(context, '/invitations'),
                        ),
                        if (FeatureFlags.enableInventory ||
                            FeatureFlags.enableExpenses ||
                            FeatureFlags.enableTasks ||
                            FeatureFlags.enableAi) ...[
                          _sep(context),
                          _label(
                            context,
                            context.translate('drawer_section_tools'),
                          ),
                          if (FeatureFlags.enableInventory)
                            _item(
                              context,
                              theme,
                              Icons.inventory_2_rounded,
                              context.translate('inventory'),
                              path.startsWith('/inventory'),
                              () => _push(context, '/inventory'),
                              enabled: hasHome,
                            ),
                          if (FeatureFlags.enableExpenses)
                            _item(
                              context,
                              theme,
                              Icons.account_balance_wallet_rounded,
                              context.translate('expenses'),
                              path.startsWith('/expenses'),
                              () => _push(context, '/expenses'),
                              enabled: hasHome,
                            ),
                          if (FeatureFlags.enableTasks)
                            _item(
                              context,
                              theme,
                              Icons.task_alt_rounded,
                              context.translate('tasks'),
                              path.contains('/tasks'),
                              () => _push(context, '/home/$homeId/tasks'),
                              enabled: hasHome,
                            ),
                          if (FeatureFlags.enableAi)
                            _item(
                              context,
                              theme,
                              Icons.auto_awesome_rounded,
                              context.translate('ai_assistant'),
                              false,
                              () => _runAfterClosingDrawer(
                                context,
                                () =>
                                    AiListSelectorSheet.show(context, homeId!),
                              ),
                              enabled: hasHome,
                              color: AppColors.accent,
                            ),
                        ],
                        _sep(context),
                        _label(
                          context,
                          context.translate('drawer_section_settings'),
                        ),
                        _item(
                          context,
                          theme,
                          Icons.settings_rounded,
                          context.translate('settings'),
                          path == '/settings',
                          () => _go(context, '/settings'),
                        ),
                        _item(
                          context,
                          theme,
                          Icons.person_rounded,
                          context.translate('profile'),
                          path == '/profile',
                          () => _push(context, '/profile'),
                        ),
                        _item(
                          context,
                          theme,
                          Icons.category_rounded,
                          context.translate('categories'),
                          path.startsWith('/categories'),
                          () => _push(context, '/categories'),
                          enabled: hasHome,
                        ),
                        _item(
                          context,
                          theme,
                          Icons.straighten_rounded,
                          context.translate('units'),
                          path.startsWith('/units'),
                          () => _push(context, '/units'),
                          enabled: hasHome,
                        ),
                        _item(
                          context,
                          theme,
                          Icons.notifications_rounded,
                          context.translate('notifications'),
                          path.startsWith('/notifications'),
                          () => _push(context, '/notifications'),
                        ),
                      ],
                    ),
                  ),
                  // ── Bottom ──
                  if (BetaConfig.isBeta)
                    _item(
                      context,
                      theme,
                      Icons.feedback_rounded,
                      context.translate('feedback'),
                      false,
                      () => _runAfterClosingDrawer(
                        context,
                        () => FeedbackBottomSheet.show(context),
                      ),
                    ),
                  _item(
                    context,
                    theme,
                    Icons.logout_rounded,
                    context.translate('sign_out'),
                    false,
                    () => _runAfterClosingDrawer(context, () async {
                      try {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) context.go('/login');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.translate('sign_out_failed'),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }),
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _header(
    BuildContext context,
    ThemeData theme,
    String name,
    String email,
    String? home,
  ) {
    final accent = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.55)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : context.translate('user'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (home != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.home_rounded, size: 13, color: accent),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      home,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────
  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, top: 8, bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────
  Widget _sep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  // ── Item ──────────────────────────────────────────────────────────────
  Widget _item(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap, {
    bool enabled = true,
    Color? color,
  }) {
    final accent = color ?? theme.colorScheme.primary;
    final fg = !enabled
        ? theme.disabledColor
        : selected
        ? accent
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled ? fg : theme.disabledColor,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: 15, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────
  static void _go(BuildContext ctx, String r) {
    final router = GoRouter.of(ctx);
    _closeDrawer(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) => router.go(r));
  }

  static void _push(BuildContext ctx, String r) {
    final router = GoRouter.of(ctx);
    _closeDrawer(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) => router.push(r));
  }

  static void _closeDrawer(BuildContext ctx) {
    final scaffold = Scaffold.maybeOf(ctx);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(ctx).pop();
    }
  }

  static void _runAfterClosingDrawer(BuildContext ctx, VoidCallback action) {
    _closeDrawer(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }
}
