import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';
import '../../../../shared/widgets/design_system/sawa_text_field.dart';

class OnboardingHomeStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController homeNameController;
  final bool isCreateMode;
  final String selectedHomeType;
  final String selectedCurrency;
  final bool isDark;
  final String Function(String key) translate;
  final ValueChanged<bool> onCreateModeChanged;
  final ValueChanged<String> onHomeTypeChanged;
  final ValueChanged<String> onCurrencyChanged;

  const OnboardingHomeStep({
    super.key,
    required this.formKey,
    required this.homeNameController,
    required this.isCreateMode,
    required this.selectedHomeType,
    required this.selectedCurrency,
    required this.isDark,
    required this.translate,
    required this.onCreateModeChanged,
    required this.onHomeTypeChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final homeTypes = [
      {
        'code': 'family',
        'name': translate('family'),
        'icon': Icons.people_outline_rounded,
      },
      {
        'code': 'couple',
        'name': translate('couple'),
        'icon': Icons.favorite_border_rounded,
      },
      {
        'code': 'single_user',
        'name': translate('single'),
        'icon': Icons.person_outline_rounded,
      },
      {
        'code': 'shared_house',
        'name': translate('shared'),
        'icon': Icons.business_outlined,
      },
    ];
    final currencies = [
      {'code': 'SAR', 'name': 'SAR - ${translate("currency_sa")}'},
      {'code': 'EGP', 'name': 'EGP - ${translate("currency_eg")}'},
      {'code': 'TRY', 'name': 'TRY - ${translate("currency_tr")}'},
      {'code': 'AED', 'name': 'AED - ${translate("currency_ae")}'},
      {'code': 'JOD', 'name': 'JOD - ${translate("currency_jo")}'},
      {'code': 'USD', 'name': 'USD - ${translate("currency_other")}'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeStepIntro(translate: translate),
            const SizedBox(height: 16),
            _HomeGuidanceCard(translate: translate),
            const SizedBox(height: 24),
            _HomeModeSwitcher(
              isCreateMode: isCreateMode,
              translate: translate,
              onChanged: onCreateModeChanged,
            ),
            const SizedBox(height: 24),
            if (isCreateMode) ...[
              SawaTextField(
                controller: homeNameController,
                labelText: translate('home_name_label'),
                hintText: translate('home_name_hint'),
                prefixIcon: Icons.home_filled,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return translate('home_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _HomeTypeGrid(
                homeTypes: homeTypes,
                selectedHomeType: selectedHomeType,
                onSelected: onHomeTypeChanged,
                translate: translate,
              ),
              const SizedBox(height: 24),
              _CurrencySelector(
                currencies: currencies,
                selectedCurrency: selectedCurrency,
                isDark: isDark,
                translate: translate,
                onChanged: onCurrencyChanged,
              ),
            ] else
              _JoinHomeCard(translate: translate),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HomeStepIntro extends StatelessWidget {
  final String Function(String key) translate;

  const _HomeStepIntro({required this.translate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('setup_home'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translate('setup_home_desc'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _HomeGuidanceCard extends StatelessWidget {
  final String Function(String key) translate;

  const _HomeGuidanceCard({required this.translate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translate('why_home_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translate('why_home_desc'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeModeSwitcher extends StatelessWidget {
  final bool isCreateMode;
  final String Function(String key) translate;
  final ValueChanged<bool> onChanged;

  const _HomeModeSwitcher({
    required this.isCreateMode,
    required this.translate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              text: translate('create_new_home'),
              selected: isCreateMode,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ModeButton(
              text: translate('join_existing_home'),
              selected: !isCreateMode,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _HomeTypeGrid extends StatelessWidget {
  final List<Map<String, Object>> homeTypes;
  final String selectedHomeType;
  final ValueChanged<String> onSelected;
  final String Function(String key) translate;

  const _HomeTypeGrid({
    required this.homeTypes,
    required this.selectedHomeType,
    required this.onSelected,
    required this.translate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('home_type_label'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: homeTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final type = homeTypes[index];
            final isSelected = selectedHomeType == type['code'];

            return AnimatedScale(
              scale: isSelected ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: SawaCard(
                hasBorder: isSelected,
                backgroundColor: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.12)
                    : null,
                onTap: () => onSelected(type['code'] as String),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['name'] as String,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? theme.primaryColor : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final List<Map<String, String>> currencies;
  final String selectedCurrency;
  final bool isDark;
  final String Function(String key) translate;
  final ValueChanged<String> onChanged;

  const _CurrencySelector({
    required this.currencies,
    required this.selectedCurrency,
    required this.isDark,
    required this.translate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('currency_label'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: isDark ? AppColors.surfaceDark : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCurrency,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: currencies.map((curr) {
                return DropdownMenuItem<String>(
                  value: curr['code'],
                  child: Text(curr['name']!, style: theme.textTheme.bodyLarge),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _JoinHomeCard extends StatelessWidget {
  final String Function(String key) translate;

  const _JoinHomeCard({required this.translate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SawaCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_unread_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              translate('join_home_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              translate('join_home_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: SawaButton(
                text: translate('check_invitations'),
                icon: Icons.list_alt_rounded,
                onPressed: () => context.push('/invitations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
