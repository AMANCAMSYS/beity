import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_bottom_sheet.dart';
import '../providers/app_settings_provider.dart';

class FontSizeBottomSheet extends ConsumerStatefulWidget {
  final double initialScale;
  final AppLocalizations l10n;

  const FontSizeBottomSheet({
    super.key,
    required this.initialScale,
    required this.l10n,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required double initialScale,
    required AppLocalizations l10n,
  }) {
    return SawaBottomSheet.show(
      context,
      title: l10n.translate('font_size'),
      child: FontSizeBottomSheet(initialScale: initialScale, l10n: l10n),
    );
  }

  @override
  ConsumerState<FontSizeBottomSheet> createState() =>
      _FontSizeBottomSheetState();
}

class _FontSizeBottomSheetState extends ConsumerState<FontSizeBottomSheet> {
  late double _currentScale;

  @override
  void initState() {
    super.initState();
    _currentScale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('font_size_sheet_desc'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapLG,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.translate('small'), style: theme.textTheme.labelMedium),
            Text(l10n.translate('normal'), style: theme.textTheme.labelMedium),
            Text(l10n.translate('large'), style: theme.textTheme.labelMedium),
            Text(l10n.translate('huge'), style: theme.textTheme.labelMedium),
          ],
        ),
        Slider(
          value: _currentScale,
          min: 0.85,
          max: 1.30,
          divisions: 3,
          label: switch (_currentScale) {
            <= 0.85 => l10n.translate('small'),
            <= 1.0 => l10n.translate('normal'),
            <= 1.15 => l10n.translate('large'),
            _ => l10n.translate('huge'),
          },
          onChanged: (value) {
            setState(() {
              _currentScale = value;
            });
            ref.read(appSettingsProvider.notifier).setFontSizeScale(value);
          },
        ),
        AppSpacing.gapMD,
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Text(
              l10n.translate('done'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
