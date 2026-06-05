import 'package:sawa/core/services/supabase_service.dart';

class ArchiveTask {
  ArchiveTask();

  Future<void> call(ArchiveTaskParams params) async {
    final client = SupabaseService.client;
    final user = client.auth.currentUser;
    if (user != null) {
      await client.from('tasks').update({
        'archived_at': DateTime.now().toIso8601String(),
        'updated_by': user.id,
      }).eq('id', params.taskId);
    }
  }
}

class ArchiveTaskParams {
  final String taskId;

  const ArchiveTaskParams({required this.taskId});
}
