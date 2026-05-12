import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/homes_provider.dart';
import '../widgets/home_card_widget.dart';

class HomesListScreen extends ConsumerStatefulWidget {
  const HomesListScreen({super.key});

  @override
  ConsumerState<HomesListScreen> createState() => _HomesListScreenState();
}

class _HomesListScreenState extends ConsumerState<HomesListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homesNotifierProvider.notifier).loadHomes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homesAsync = ref.watch(homesNotifierProvider);
    final activeHomeIdAsync = ref.watch(activeHomeIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(' المنازل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(homesNotifierProvider.notifier).refreshHomes();
            },
          ),
        ],
      ),
      body: homesAsync.when(
        data: (homes) {
          if (homes.isEmpty) {
            return _buildEmptyState(context);
          }

          final activeHomeId = activeHomeIdAsync.valueOrNull;

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(homesNotifierProvider.notifier).refreshHomes();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: homes.length,
              itemBuilder: (context, index) {
                final home = homes[index];
                final isActive = home.id == activeHomeId;

                return HomeCardWidget(
                  home: home,
                  isActive: isActive,
                  onTap: () async {
                    final localDataSource =
                        ref.read(homeLocalDataSourceProvider);
                    await localDataSource.setActiveHome(home.id, home.name);
                    ref.invalidate(activeHomeIdProvider);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(homesNotifierProvider.notifier).loadHomes();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/homes/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد منازل',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'أنشئ منزلك الأول لتبدأ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/homes/create'),
              icon: const Icon(Icons.add),
              label: const Text('إنشاء منزل'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
