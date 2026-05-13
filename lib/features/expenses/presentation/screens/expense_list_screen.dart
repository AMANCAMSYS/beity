import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_card.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ExpenseListScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    // Use filtered provider
    final expensesAsync = ref.watch(expensesProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          // Apply client-side filters
          var filteredExpenses = expenses;

          if (_startDate != null) {
            filteredExpenses = filteredExpenses
                .where((e) => e.date.isAfter(_startDate!))
                .toList();
          }
          if (_endDate != null) {
            filteredExpenses = filteredExpenses
                .where((e) => e.date.isBefore(_endDate!.add(const Duration(days: 1))))
                .toList();
          }
          if (_selectedCategoryId != null) {
            filteredExpenses = filteredExpenses
                .where((e) => e.categoryId == _selectedCategoryId)
                .toList();
          }
          if (_selectedMemberId != null) {
            filteredExpenses = filteredExpenses
                .where((e) => e.paidBy == _selectedMemberId)
                .toList();
          }

          if (filteredExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    expenses.isEmpty
                        ? 'لا توجد مصروفات بعد'
                        : 'لا توجد مصروفات تطابق الفلتر',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expenses.isEmpty
                        ? 'اضغط على + لإضافة مصروف جديد'
                        : 'جرب تغيير الفلتر',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) {
              final expense = filteredExpenses[index];
              return ExpenseCard(
                expense: expense,
                onTap: () {
                  context.push('/expenses/${expense.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('خطأ: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(expensesProvider(widget.homeId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/expenses/add/${widget.homeId}');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تصفية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('من تاريخ'),
                subtitle: Text(_startDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : 'غير محدد'),
                trailing: _startDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setDialogState(() => _startDate = null);
                        },
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => _startDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('إلى تاريخ'),
                subtitle: Text(_endDate != null
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : 'غير محدد'),
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setDialogState(() => _endDate = null);
                        },
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => _endDate = picked);
                  }
                },
              ),
              // TODO: Add category filter
              // TODO: Add member filter
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedCategoryId = null;
                  _selectedMemberId = null;
                });
                Navigator.pop(context);
              },
              child: const Text('مسح الفلاتر'),
            ),
            TextButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild with new filters
                Navigator.pop(context);
              },
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }
}
