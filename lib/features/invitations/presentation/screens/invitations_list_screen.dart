import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/invitations_provider.dart';
import '../widgets/invitation_card_widget.dart';
import '../../../../core/localization/app_localizations.dart';

class InvitationsListScreen extends ConsumerWidget {
  final String? homeId;

  const InvitationsListScreen({super.key, this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = homeId != null
        ? ref.watch(homeInvitationsStreamProvider(homeId!))
        : ref.watch(userInvitationsStreamProvider);

    ref.listen<AsyncValue<void>>(invitationNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceAll('Exception: ', '')),
            ),
          );
        },
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.translate('action_success'))),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          homeId != null
              ? context.translate('home_invitations')
              : context.translate('my_invitations'),
        ),
      ),
      body: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    homeId != null
                        ? context.translate('no_pending_invitations_home')
                        : context.translate('no_pending_invitations_user'),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    homeId != null
                        ? context.translate('invite_members_from_settings')
                        : context.translate('received_invitations_here'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return InvitationCardWidget(
                invitation: invitation,
                isOwner: homeId != null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(context.translate('load_invitations_failed')),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                  homeId != null
                      ? homeInvitationsStreamProvider(homeId!)
                      : userInvitationsStreamProvider,
                ),
                child: Text(context.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
