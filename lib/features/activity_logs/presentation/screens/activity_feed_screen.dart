import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BeityEmptyState(
      title: isArabic ? 'لا توجد نشاطات بعد' : 'No activities yet',
      message: isArabic
          ? 'ستظهر النشاطات عندما يتفاعل الأعضاء مع القوائم والمنتجات'
          : 'Activities will appear when members interact with lists and products',
      icon: Icons.history_rounded,
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BeityEmptyState(
      title: isArabic ? 'حدث خطأ' : 'An error occurred',
      message: error,
      icon: Icons.error_outline_rounded,
      isError: true,
      actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
      onAction: () => ref.invalidate(homeActivityProvider(widget.homeId)),
    );
  }

  void _navigateToDetail(ActivityLogModel log) {
    context.push('/activity/${log.id}', extra: log);
  }
}
