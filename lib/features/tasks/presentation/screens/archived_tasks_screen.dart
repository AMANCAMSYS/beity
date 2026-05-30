import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import '../../../../shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/core/localization/app_localizations.dart';

class ArchivedTasksScreen extends ConsumerWidget {
  final String homeId;

  const ArchivedTasksScreen({
    super.key,
    required this.homeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(taskRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.translate('archived_tasks')),
      ),
      body: FutureBuilder(
        future: repository.getTasks(
          homeId: homeId,
          activeOnly: false,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return BeityEmptyState(
              title: context.translate('error_occurred'),
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
              isError: true,
            );
          }

          final tasks = snapshot.data ?? [];
          final archivedTasks =
              tasks.where((t) => t.isArchived).toList();

          if (archivedTasks.isEmpty) {
            return BeityEmptyState(
              title: context.translate('no_archived_tasks'),
              message: context.translate('archived_tasks_desc'),
              icon: Icons.archive_outlined,
            );
          }

          return ListView.builder(
            itemCount: archivedTasks.length,
            itemBuilder: (context, index) {
              final task = archivedTasks[index];
              return TaskCard(
                task: task,
                onTap: () {
                  context.push('/home/$homeId/tasks/${task.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
