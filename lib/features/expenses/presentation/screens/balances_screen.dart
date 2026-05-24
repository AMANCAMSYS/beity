import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../providers/balance_providers.dart';
import '../widgets/balance_card.dart';

class BalancesScreen extends ConsumerWidget {
  final String homeId;

  const BalancesScreen({
    super.key,
    required this.homeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(balancesProvider(homeId));
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الأرصدة والتسويات' : 'Balances & Settlements', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: balancesAsync.when(
        data: (balances) {
          if (balances.isEmpty) {
            return BeityEmptyState(
              title: isArabic ? 'تم تسوية جميع الحسابات' : 'All accounts settled',
              message: isArabic 
                  ? 'لا توجد مبالغ مستحقة بين أعضاء المنزل حالياً. حافظ على هذا التوازن الجميل!' 
                  : 'No outstanding amounts between members. Keep up this great balance!',
              icon: Icons.check_circle_outline_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            itemCount: balances.length,
            itemBuilder: (context, index) {
              final balance = balances[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: BalanceCard(balance: balance),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => BeityEmptyState(
          title: isArabic ? 'عذراً، حدث خطأ' : 'Oops, something went wrong',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
          onActionPressed: () => ref.invalidate(balancesProvider(homeId)),
        ),
      ),
    );
  }
}
