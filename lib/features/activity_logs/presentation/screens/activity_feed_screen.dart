import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/activity_log_model.dart';
import '../providers/activity_logs_provider.dart';
import '../widgets/activity_log_tile_widget.dart';
import '../widgets/activity_filter_widget.dart';

class ActivityFeedScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ActivityFeedScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<ActivityFeedScreen> createState() =>
      _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends ConsumerState<ActivityFeedScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  List<ActivityLogModel> _allLogs = [];
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final repository = ref.read(activityLogRepositoryProvider);
    final filter = ref.read(activityFilterProvider);

    final moreLogs = await repository.getActivityLogs(
      homeId: widget.homeId,
      actorId: filter.actorId,
      actionTypes: filter.actionTypes,
      limit: 50,
      offset: _allLogs.length,
    );

    if (mounted) {
      setState(() {
        _allLogs.addAll(moreLogs);
        _hasMore = moreLogs.length >= 50;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(activityFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النشاطات'),
        actions: [
          if (filter.isActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'مسح الفلاتر',
              onPressed: () =>
                  ref.read(activityFilterProvider.notifier).clear(),
            ),
        ],
      ),
      body: _buildBody(context, filter),
    );
  }

  Widget _buildBody(BuildContext context, ActivityFilter filter) {
    return Column(
      children: [
        ActivityFilterWidget(homeId: widget.homeId),
        Expanded(
          child: filter.isActive
              ? _buildFilteredList(context, filter)
              : _buildStreamedList(context),
        ),
      ],
    );
  }

  Widget _buildStreamedList(BuildContext context) {
    final activityAsync = ref.watch(homeActivityProvider(widget.homeId));

    return activityAsync.when(
      data: (logs) {
        _allLogs = logs;
        if (logs.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildList(context, logs);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildFilteredList(BuildContext context, ActivityFilter filter) {
    final repository = ref.read(activityLogRepositoryProvider);

    return FutureBuilder<List<ActivityLogModel>>(
      future: repository.getActivityLogs(
        homeId: widget.homeId,
        actorId: filter.actorId,
        actionTypes: filter.actionTypes,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildList(context, logs);
      },
    );
  }

  Widget _buildList(BuildContext context, List<ActivityLogModel> logs) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeActivityProvider(widget.homeId));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: logs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == logs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final log = logs[index];
          return ActivityLogTileWidget(
            log: log,
            onTap: () => _navigateToDetail(log),
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
              'لا توجد نشاطات بعد',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر النشاطات عندما يتفاعل الأعضاء مع القوائم والمنتجات',
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

  Widget _buildErrorState(BuildContext context, String error) {
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
              onPressed: () =>
                  ref.invalidate(homeActivityProvider(widget.homeId)),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(ActivityLogModel log) {
    context.push('/activity/${log.id}', extra: log);
  }
}
