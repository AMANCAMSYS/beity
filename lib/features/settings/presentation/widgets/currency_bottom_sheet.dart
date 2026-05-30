import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/beity_bottom_sheet.dart';
import '../../../homes/presentation/providers/homes_provider.dart';

class CurrencyBottomSheet extends ConsumerWidget {
  final String homeId;
  final String currentCurrency;
  final AppLocalizations l10n;

  const CurrencyBottomSheet({
    super.key,
    required this.homeId,
    required this.currentCurrency,
    required this.l10n,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String homeId,
    required String currentCurrency,
    required AppLocalizations l10n,
  }) {
    return BeityBottomSheet.show(
      context,
      title: l10n.translate('select_default_currency'),
      child: CurrencyBottomSheet(
        homeId: homeId,
        currentCurrency: currentCurrency,
        l10n: l10n,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencies = [
      {'code': 'TRY', 'name': 'Türk Lirası (TRY)'},
      {'code': 'SAR', 'name': 'SAR - ريال سعودي'},
      {'code': 'USD', 'name': 'USD - دولار أمريكي'},
      {'code': 'EUR', 'name': 'EUR - يورو'},
      {'code': 'EGP', 'name': 'EGP - جنيه مصري'},
      {'code': 'AED', 'name': 'AED - درهم إماراتي'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currencies.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final curr = currencies[index];
        final code = curr['code']!;
        final name = curr['name']!;
        final isSelected = code == currentCurrency;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_rounded,
                  color: theme.colorScheme.primary,
                )
              : null,
          onTap: () async {
            Navigator.pop(context);
            try {
              final repo = ref.read(homeRepositoryProvider);
              await repo.updateHomeCurrency(
                homeId: homeId,
                currency: code,
              );

              // Invalidate and reload homes
              ref.invalidate(userHomesProvider);
              ref.read(homesNotifierProvider.notifier).refreshHomes();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.translate('currency_updated_success', arguments: {'code': code}),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.translate('currency_updated_failed', arguments: {'error': e.toString()}),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
