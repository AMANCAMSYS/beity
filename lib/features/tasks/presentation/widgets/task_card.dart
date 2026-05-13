import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final String? assigneeName;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.assigneeName,
  });

  Color _getDueDateColor() {
    if (task.isOverdue) return Colors.red;
    if (task.isDueToday) return Colors.orange;
    return Colors.grey;
  }

  String _getDueDateText() {
    if (task.dueDate == null) return '';
    final now = DateTime.now();
    final due = task.dueDate!;
    final difference = due.difference(now).inDays;

    if (task.isOverdue) return 'متأخرة';
    if (task.isDueToday) return 'اليوم';
    if (difference == 1) return 'غداً';
    return '${due.day}/${due.month}/${due.year}';
  }

  String _getRecurrenceText() {
    switch (task.recurrenceType) {
      case 'daily':
        return 'يومياً';
      case 'weekly':
        return 'أسبوعياً';
      case 'monthly':
        return 'شهرياً';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: onComplete != null ? (_) => onComplete!() : null,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (task.assignedTo != null && assigneeName != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        assigneeName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                if (task.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: _getDueDateColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDueDateText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getDueDateColor(),
                          fontWeight: task.isOverdue || task.isDueToday
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ],
                  ),
                if (task.isRecurring)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _getRecurrenceText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        trailing: task.isCompleted
            ? Icon(Icons.check_circle, color: Colors.green.shade400)
            : null,
      ),
    );
  }
}
