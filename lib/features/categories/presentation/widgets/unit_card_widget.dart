import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../../../core/errors/error_formatter.dart';
import '../../../../app/theme/app_colors.dart';
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
            color: _getUnitColor().withValues(alpha: 0.1),
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
          textDirection: Directionality.of(context),
        ),
        subtitle: Text(
          '${_getTypeName(context)} • ${unit.symbol}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textDirection: Directionality.of(context),
        ),
        trailing: !unit.isDefault && showActions
            ? IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 20,
                  color: AppColors.error,
                ),
                onPressed: () => _deleteUnit(context, ref),
              )
            : null,
      ),
    );
  }

  Color _getUnitColor() {
    switch (unit.type) {
      case UnitType.weight:
        return AppColors.warning;
      case UnitType.volume:
        return AppColors.info;
      case UnitType.count:
        return AppColors.success;
      case UnitType.length:
        return AppColors.secondary;
    }
  }

  String _getTypeName(BuildContext context) {
    switch (unit.type) {
      case UnitType.weight:
        return context.translate('weight');
      case UnitType.volume:
        return context.translate('volume');
      case UnitType.count:
        return context.translate('count');
      case UnitType.length:
        return context.translate('length');
    }
  }

  void _deleteUnit(BuildContext outerContext, WidgetRef ref) {
    showDialog(
      context: outerContext,
      builder: (context) => AlertDialog(
        title: Text(
          outerContext.translate('delete_unit'),
          textDirection: Directionality.of(outerContext),
        ),
        content: Text(
          outerContext.translate(
            'delete_unit_confirm',
            arguments: {'name': unit.name},
          ),
          textDirection: Directionality.of(outerContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(unitNotifierProvider.notifier)
                    .deleteUnit(unitId: unit.id);
                if (context.mounted) {
                  SawaSnackBar.success(
                    context,
                    context.translate('unit_deleted_success'),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  SawaSnackBar.error(
                    context,
                    ErrorFormatter.format(e, context),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.translate('delete')),
          ),
        ],
      ),
    );
  }
}
