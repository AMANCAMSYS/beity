import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../data/datasources/task_comment_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/repositories/task_comment_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/task_comment_repository.dart';

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final client = Supabase.instance.client;
  return TaskRemoteDataSource(client);
});

final taskCommentRemoteDataSourceProvider =
    Provider<TaskCommentRemoteDataSource>((ref) {
  final client = Supabase.instance.client;
  return TaskCommentRemoteDataSource(client);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dataSource = ref.watch(taskRemoteDataSourceProvider);
  return TaskRepositoryImpl(dataSource);
});

final taskCommentRepositoryProvider = Provider<TaskCommentRepository>((ref) {
  final dataSource = ref.watch(taskCommentRemoteDataSourceProvider);
  return TaskCommentRepositoryImpl(dataSource);
});

final tasksProvider =
    StreamProvider.autoDispose.family<List<Task>, ({String homeId, String? assignedTo})>(
        (ref, params) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks(
    homeId: params.homeId,
    assignedTo: params.assignedTo,
  );
});

final taskByIdProvider =
    FutureProvider.family<Task?, String>((ref, taskId) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTaskById(taskId: taskId);
});

final taskCommentsProvider =
    StreamProvider.autoDispose.family<List<TaskComment>, String>((ref, taskId) {
  final repository = ref.watch(taskCommentRepositoryProvider);
  return repository.watchComments(taskId: taskId);
});
