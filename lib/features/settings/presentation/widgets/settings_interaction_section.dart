import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import 'settings_shared_widgets.dart';

class SettingsInteractionSection extends ConsumerWidget {
  final AppSettingsState settings;
  final AppLocalizations l10n;

  const SettingsInteractionSection({
    super.key,
    required this.settings,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = l10n.translate('interaction_and_sounds');

    return SettingsSection(
      title: title,
      children: [
        SettingsSwitchTile(
          icon: Icons.vibration_rounded,
          title: l10n.translate('haptic_feedback'),
          subtitle: l10n.translate('haptic_feedback_subtitle'),
          value: settings.hapticFeedback,
          onChanged: (value) =>
              ref.read(appSettingsProvider.notifier).setHapticFeedback(value),
        ),
        const SettingsDivider(),
        SettingsSwitchTile(
          icon: Icons.volume_up_rounded,
          title: l10n.translate('sound_effects'),
          subtitle: l10n.translate('sound_effects_subtitle'),
          value: settings.soundEffects,
          onChanged: (value) =>
              ref.read(appSettingsProvider.notifier).setSoundEffects(value),
        ),
      ],
    );
  }
}
