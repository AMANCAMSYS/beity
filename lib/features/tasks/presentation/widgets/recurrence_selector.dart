import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class RecurrenceSelector extends StatelessWidget {
  final String? selectedRecurrence;
  final ValueChanged<String?> onChanged;

  const RecurrenceSelector({
    super.key,
    this.selectedRecurrence,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('recurrence_optional'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(context.translate('none')),
              selected: selectedRecurrence == null,
              onSelected: (_) => onChanged(null),
            ),
            ChoiceChip(
              label: Text(context.translate('daily')),
              selected: selectedRecurrence == 'daily',
              onSelected: (_) => onChanged('daily'),
            ),
            ChoiceChip(
              label: Text(context.translate('weekly')),
              selected: selectedRecurrence == 'weekly',
              onSelected: (_) => onChanged('weekly'),
            ),
            ChoiceChip(
              label: Text(context.translate('monthly')),
              selected: selectedRecurrence == 'monthly',
              onSelected: (_) => onChanged('monthly'),
            ),
          ],
        ),
      ],
    );
  }
}
