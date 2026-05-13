import 'package:flutter/material.dart';
import '../../domain/entities/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: expense.isCancelled
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
          child: Icon(
            Icons.receipt_long,
            color: Colors.white,
          ),
        ),
        title: Text(
          expense.description,
          style: TextStyle(
            decoration:
                expense.isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(expense.convertedAmount / 100).toStringAsFixed(2)} ر.س',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (expense.isCancelled)
              Text(
                'ملغي',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
