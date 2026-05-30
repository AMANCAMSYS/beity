import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../onboarding/presentation/providers/app_tour_controller.dart';
import '../../../onboarding/data/onboarding_storage.dart';
import 'settings_shared_widgets.dart';

class SettingsOnboardingSection extends ConsumerWidget {
  final AppLocalizations l10n;

  const SettingsOnboardingSection({
    super.key,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = l10n.locale.languageCode;
    final title = languageCode == 'ar'
        ? 'التعريف والتوجيه'
        : languageCode == 'tr'
            ? 'Tanıtım ve Rehberlik'
            : 'Onboarding & Guide';

    return SettingsSection(
      title: title,
      children: [
        SettingsActionTile(
          icon: Icons.slideshow_rounded,
          title: l10n.translate('replay_welcome_tour'),
          subtitle: l10n.translate('replay_welcome_tour_subtitle'),
          onTap: () async {
            await OnboardingStorage.resetWelcomeOnboarding();
            if (context.mounted) {
              context.push('/onboarding');
            }
          },
        ),
        const SettingsDivider(),
        SettingsActionTile(
          icon: Icons.touch_app_rounded,
          title: l10n.translate('replay_app_tour'),
          subtitle: l10n.translate('replay_app_tour_subtitle'),
          onTap: () async {
            // Replay the tour starting from home
            if (context.canPop()) {
              context.pop(); // Close settings if open
            }
            context.go('/'); // Ensure we're on the home tab
            await Future.delayed(const Duration(milliseconds: 300));
            if (context.mounted) {
              ref.read(appTourControllerProvider.notifier).replayTour(context);
            }
          },
        ),
      ],
    );
  }
}
