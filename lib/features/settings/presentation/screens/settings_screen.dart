import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/features/auth/presentation/providers/auth_provider.dart';
import 'package:beity/features/homes/presentation/providers/homes_provider.dart';
import 'package:beity/features/home/presentation/widgets/app_drawer.dart';
import 'package:beity/features/home/presentation/widgets/drawer_toggle_button.dart';
import 'package:beity/features/settings/presentation/providers/app_settings_provider.dart';
import '../widgets/settings_shared_widgets.dart';
import '../widgets/settings_account_section.dart';
import '../widgets/settings_home_section.dart';
import '../widgets/settings_preferences_section.dart';
import '../widgets/settings_interaction_section.dart';
import '../widgets/settings_shopping_section.dart';
import '../widgets/settings_data_section.dart';
import '../widgets/settings_onboarding_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leadingWidth: 62,
        leading: Builder(builder: (context) => const DrawerToggleButton()),
        title: Text(l10n.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: const [
          _AccountHeaderWidget(),
          AppSpacing.gapLG,
          _AccountSectionWidget(),
          AppSpacing.gapLG,
          _HomeSectionWidget(),
          AppSpacing.gapLG,
          _PreferencesSectionWidget(),
          AppSpacing.gapLG,
          _InteractionSectionWidget(),
          AppSpacing.gapLG,
          _OnboardingSectionWidget(),
          AppSpacing.gapLG,
          _ShoppingSectionWidget(),
          AppSpacing.gapLG,
          _DataSectionWidget(),
          AppSpacing.gapMD,
          _AppVersionWidget(),
        ],
      ),
    );
  }
}

class _AccountHeaderWidget extends ConsumerWidget {
  const _AccountHeaderWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final isArabic = settings.locale.languageCode == 'ar';
    final user = ref.watch(cachedCurrentUserProvider);
    
    final displayName = user?.fullName ??
        (isArabic
            ? 'المستخدم'
            : settings.locale.languageCode == 'tr'
                ? 'Kullanıcı'
                : 'User');
    final email = user?.email ?? '';

    return AccountSummaryCard(
      displayName: displayName,
      email: email,
      label: l10n.translate('edit_profile_tap'),
      onProfileTap: () => context.push('/profile'),
    );
  }
}

class _AccountSectionWidget extends ConsumerWidget {
  const _AccountSectionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return SettingsAccountSection(l10n: l10n);
  }
}

class _HomeSectionWidget extends ConsumerWidget {
  const _HomeSectionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final activeHomeId = ref.watch(cachedActiveHomeIdProvider);
    final activeHome = ref.watch(cachedActiveHomeProvider);

    return SettingsHomeSection(
      activeHomeId: activeHomeId,
      activeHome: activeHome,
      l10n: l10n,
    );
  }
}

class _PreferencesSectionWidget extends ConsumerWidget {
  const _PreferencesSectionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    return SettingsPreferencesSection(settings: settings, l10n: l10n);
  }
}

class _InteractionSectionWidget extends ConsumerWidget {
  const _InteractionSectionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    return SettingsInteractionSection(settings: settings, l10n: l10n);
  }
}

class _ShoppingSectionWidget extends ConsumerWidget {
  const _ShoppingSectionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    return SettingsShoppingSection(settings: settings, l10n: l10n);
  }
}

class _DataSectionWidget extends ConsumerWidget {
  const _DataSectionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    return SettingsDataSection(settings: settings, l10n: l10n);
  }
}

class _OnboardingSectionWidget extends ConsumerWidget {
  const _OnboardingSectionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    return SettingsOnboardingSection(l10n: l10n);
  }
}

class _AppVersionWidget extends ConsumerWidget {
  const _AppVersionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isArabic = settings.locale.languageCode == 'ar';
    return Center(
      child: Text(
        '${isArabic ? "بيتي" : "Beity"} 1.0.0',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
