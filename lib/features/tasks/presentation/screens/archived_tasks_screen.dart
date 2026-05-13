import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';

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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('خطأ: ${snapshot.error}'),
                ],
              ),
            );
          }

          final tasks = snapshot.data ?? [];
          final archivedTasks =
              tasks.where((t) => t.isArchived).toList();

          if (archivedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('لا توجد مهام مؤرشفة'),
                  const SizedBox(height: 8),
                  Text(
                    'تُؤرشف المهام المكتملة تلقائياً بعد 7 أيام',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
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
