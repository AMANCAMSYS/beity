import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/activity_log_model.dart';
import '../providers/activity_logs_provider.dart';
import '../widgets/activity_log_tile_widget.dart';

class ListActivityScreen extends ConsumerWidget {
  final String homeId;
  final String listId;
  final String listName;

  const ListActivityScreen({
    super.key,
    required this.homeId,
    required this.listId,
    required this.listName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync =
        ref.watch(listActivityProvider([homeId, listId]));

    return Scaffold(
      appBar: AppBar(
        title: Text('نشاطات $listName'),
      ),
      body: activityAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildList(context, ref, logs);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<ActivityLogModel> logs) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(listActivityProvider([homeId, listId]));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return ActivityLogTileWidget(
            log: log,
            onTap: () => context.push('/activity/${log.id}', extra: log),
          );
        },
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
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد نشاطات لهذه القائمة',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر النشاطات عند إضافة أو تعديل أو شراء المنتجات',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(
                  listActivityProvider([homeId, listId])),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
