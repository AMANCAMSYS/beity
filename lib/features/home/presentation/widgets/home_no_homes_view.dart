import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import 'drawer_toggle_button.dart';
import 'app_drawer.dart';
import '../../../notifications/presentation/widgets/notification_badge_widget.dart';
import '../../../invitations/presentation/widgets/invitation_card_widget.dart';
import '../../../invitations/presentation/providers/invitations_provider.dart';
import '../../../../core/errors/error_formatter.dart';

class HomeNoHomesView extends ConsumerWidget {
  const HomeNoHomesView({super.key});

  String _getUserName(BuildContext context, WidgetRef ref) {
    final user = ref.watch(cachedCurrentUserProvider);
    if (user != null && user.fullName.isNotEmpty) return user.fullName;
    return user?.email ?? context.translate('user_label');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(userInvitationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 62,
        leading: Builder(builder: (context) => const DrawerToggleButton()),
        title: Text(
          context.translate('sawa'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
              SawaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
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
                                '${context.translate('welcome_to_sawa')} 👋',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getUserName(context, ref),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.translate('home_screen_no_homes_desc'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: SawaButton(
                        onPressed: () => context.push('/homes/create'),
                        text: context.translate('create_new_home'),
                        icon: Icons.add_home_outlined,
                        type: SawaButtonType.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Invitations Section
              Text(
                context.translate('my_invitations'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              invitationsAsync.when(
                data: (invitations) {
                  final pendingInvitations = invitations
                      .where((inv) => inv.isPending)
                      .toList();
                  if (pendingInvitations.isEmpty) {
                    return SawaCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.translate(
                                  'no_pending_invitations_user',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.6),
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
                error: (err, _) => SawaCard(
                  child: Text(
                    context.translate(
                      'error_loading_invitations',
                      arguments: {'error': ErrorFormatter.format(err, context)},
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
