import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/core/errors/error_formatter.dart';

class CommentThread extends ConsumerStatefulWidget {
  final String taskId;

  const CommentThread({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends ConsumerState<CommentThread> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final repository = ref.read(taskCommentRepositoryProvider);
      await repository.addComment(
        taskId: widget.taskId,
        content: content,
      );
      _commentController.clear();
      ref.invalidate(taskCommentsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.translate('error_occurred')}: ${ErrorFormatter.format(e, context)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('comments'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.translate('no_comments_yet'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person, size: 20),
                  ),
                  title: Text(comment.content),
                  subtitle: Text(
                    comment.createdAt != null
                        ? '${comment.createdAt!.day}/${comment.createdAt!.month}/${comment.createdAt!.year} ${comment.createdAt!.hour}:${comment.createdAt!.minute.toString().padLeft(2, '0')}'
                        : '',
                  ),
                  dense: true,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('${context.translate('error_occurred')}: ${ErrorFormatter.format(error, context)}'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: context.translate('add_comment_placeholder'),
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _addComment,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}
