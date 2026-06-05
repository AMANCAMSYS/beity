import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import 'settings_shared_widgets.dart';

class SettingsShoppingSection extends ConsumerWidget {
  final AppSettingsState settings;
  final AppLocalizations l10n;

  const SettingsShoppingSection({
    super.key,
    required this.settings,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = l10n.translate('shopping_mode_and_lists');

    return SettingsSection(
      title: title,
      children: [
        SettingsSwitchTile(
          icon: Icons.screen_lock_rotation_rounded,
          title: l10n.translate('keep_screen_on'),
          subtitle: l10n.translate('keep_screen_on_subtitle'),
          value: settings.keepScreenOn,
          onChanged: (value) =>
              ref.read(appSettingsProvider.notifier).setKeepScreenOn(value),
        ),
        const SettingsDivider(),
        SettingsSwitchTile(
          icon: Icons.view_headline_rounded,
          title: l10n.translate('compact_list_mode'),
          subtitle: l10n.translate('compact_list_mode_subtitle'),
          value: settings.compactListMode,
          onChanged: (value) =>
              ref.read(appSettingsProvider.notifier).setCompactListMode(value),
        ),
        const SettingsDivider(),
        SettingsSwitchTile(
          icon: Icons.grid_view_rounded,
          title: l10n.translate('grouped_by_category'),
          subtitle: l10n.translate('grouped_by_category_subtitle'),
          value: settings.groupedByCategory,
          onChanged: (value) => ref
              .read(appSettingsProvider.notifier)
              .setGroupedByCategory(value),
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.tune_rounded,
          title: l10n.translate('notification_settings'),
          subtitle: l10n.translate('notification_categories_desc'),
          onTap: () => context.push('/notifications/preferences'),
        ),
        const SettingsDivider(),
        SettingsSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: l10n.translate('purchase_notifications'),
          subtitle: l10n.translate('purchase_notifications_subtitle'),
          value: settings.purchaseNotifications,
          onChanged: (value) => ref
              .read(appSettingsProvider.notifier)
              .setPurchaseNotifications(value),
        ),
      ],
    );
  }
}
