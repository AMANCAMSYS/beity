import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرصدة'),
      ),
      body: balancesAsync.when(
        data: (balances) {
          if (balances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تم تسوية جميع الحسابات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد ديون بين الأعضاء',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: balances.length,
            itemBuilder: (context, index) {
              final balance = balances[index];
              return BalanceCard(balance: balance);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
