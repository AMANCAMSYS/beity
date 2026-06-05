import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'settings_shared_widgets.dart';

class SettingsAccountSection extends ConsumerWidget {
  final AppLocalizations l10n;

  const SettingsAccountSection({super.key, required this.l10n});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      final deleteLocalData = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.translate('sign_out_choice_title')),
          content: Text(l10n.translate('sign_out_choice_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.translate('sign_out_keep_data')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(l10n.translate('sign_out_delete_data')),
            ),
          ],
        ),
      );
      if (deleteLocalData == null) return;

      await ref
          .read(authNotifierProvider.notifier)
          .signOut(deleteLocalData: deleteLocalData);
      if (context.mounted) context.go('/login');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate(
                'sign_out_failed',
                arguments: {'error': error.toString()},
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: l10n.translate('account_area'),
      children: [
        SettingsActionTile(
          icon: Icons.notifications_rounded,
          title: l10n.translate('notification_settings'),
          subtitle: l10n.translate('notification_settings_subtitle'),
          onTap: () => context.push('/notifications/preferences'),
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          title: l10n.translate('sign_out'),
          subtitle: l10n.translate('sign_out_subtitle'),
          titleColor: AppColors.error,
          onTap: () => _signOut(context, ref),
        ),
      ],
    );
  }
}
