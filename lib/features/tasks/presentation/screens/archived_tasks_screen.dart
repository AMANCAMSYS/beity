import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import '../../../home/presentation/widgets/app_drawer.dart';
import '../../../../shared/widgets/design_system/beity_empty_state.dart';

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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('المهام المؤرشفة'),
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
              title: 'حدث خطأ',
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
              isError: true,
            );
          }

          final tasks = snapshot.data ?? [];
          final archivedTasks =
              tasks.where((t) => t.isArchived).toList();

          if (archivedTasks.isEmpty) {
            return const BeityEmptyState(
              title: 'لا توجد مهام مؤرشفة',
              message: 'تُؤرشف المهام المكتملة تلقائياً بعد 7 أيام',
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
