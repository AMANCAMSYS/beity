import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../homes/data/models/home_model.dart';
import 'currency_bottom_sheet.dart';
import 'settings_shared_widgets.dart';

class SettingsHomeSection extends ConsumerWidget {
  final String? activeHomeId;
  final HomeModel? activeHome;
  final AppLocalizations l10n;

  const SettingsHomeSection({
    super.key,
    required this.activeHomeId,
    required this.activeHome,
    required this.l10n,
  });

  void _showNoActiveHomeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(l10n.translate('no_active_home')),
        content: Text(l10n.translate('active_home_required')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/homes');
            },
            child: Text(l10n.translate('manage_homes')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: l10n.translate('home_organization'),
      children: [
        SettingsActionTile(
          icon: Icons.home_work_rounded,
          title: l10n.translate('manage_homes'),
          subtitle: l10n.translate('manage_homes_subtitle'),
          onTap: () => context.push('/homes'),
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.group_rounded,
          title: l10n.translate('members_roles'),
          subtitle: l10n.translate('members_roles_subtitle'),
          onTap: () {
            if (activeHomeId != null && activeHomeId!.isNotEmpty) {
              context.push('/homes/$activeHomeId/members');
            } else {
              _showNoActiveHomeDialog(context);
            }
          },
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.payments_rounded,
          title: l10n.translate('default_currency'),
          subtitle: activeHome != null
              ? l10n.translate('current_currency', arguments: {'currency': activeHome!.defaultCurrency ?? "TRY"})
              : l10n.translate('default_currency_subtitle'),
          onTap: () {
            if (activeHomeId != null && activeHomeId!.isNotEmpty) {
              CurrencyBottomSheet.show(
                context,
                ref,
                homeId: activeHomeId!,
                currentCurrency: activeHome?.defaultCurrency ?? 'TRY',
                l10n: l10n,
              );
            } else {
              _showNoActiveHomeDialog(context);
            }
          },
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.category_rounded,
          title: l10n.translate('categories'),
          subtitle: l10n.translate('categories_subtitle'),
          onTap: () => context.push('/categories'),
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.straighten_rounded,
          title: l10n.translate('units'),
          subtitle: l10n.translate('units_subtitle'),
          onTap: () => context.push('/units'),
        ),
      ],
    );
  }
}
