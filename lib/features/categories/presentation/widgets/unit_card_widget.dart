import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/unit_model.dart';
import '../../domain/entities/unit.dart';
import '../providers/units_provider.dart';

class UnitCardWidget extends ConsumerWidget {
  final UnitModel unit;
  final bool showActions;

  const UnitCardWidget({
    super.key,
    required this.unit,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getUnitColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              unit.symbol,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getUnitColor(),
              ),
            ),
          ),
        ),
        title: Text(
          unit.name,
          style: Theme.of(context).textTheme.titleMedium,
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          '${_getTypeName()} • ${unit.symbol}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textDirection: TextDirection.rtl,
        ),
        trailing: !unit.isDefault && showActions
            ? IconButton(
                icon: const Icon(Icons.delete,
                    size: 20, color: Colors.red),
                onPressed: () => _deleteUnit(context, ref),
              )
            : null,
      ),
    );
  }

  Color _getUnitColor() {
    switch (unit.type) {
      case UnitType.weight:
        return Colors.orange;
      case UnitType.volume:
        return Colors.blue;
      case UnitType.count:
        return Colors.green;
      case UnitType.length:
        return Colors.purple;
    }
  }

  String _getTypeName() {
    switch (unit.type) {
      case UnitType.weight:
        return 'وزن';
      case UnitType.volume:
        return 'حجم';
      case UnitType.count:
        return 'عدد';
      case UnitType.length:
        return 'طول';
    }
  }

  void _deleteUnit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف الوحدة',
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل أنت متأكد من حذف "${unit.name}"؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(unitNotifierProvider.notifier)
                    .deleteUnit(unitId: unit.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم حذف الوحدة بنجاح',
                        textDirection: TextDirection.rtl,
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                        textDirection: TextDirection.rtl,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
