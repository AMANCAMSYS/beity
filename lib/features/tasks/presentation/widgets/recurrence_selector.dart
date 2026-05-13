import 'package:flutter/material.dart';

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
        const Text(
          'التكرار (اختياري)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('بدون'),
              selected: selectedRecurrence == null,
              onSelected: (_) => onChanged(null),
            ),
            ChoiceChip(
              label: const Text('يومياً'),
              selected: selectedRecurrence == 'daily',
              onSelected: (_) => onChanged('daily'),
            ),
            ChoiceChip(
              label: const Text('أسبوعياً'),
              selected: selectedRecurrence == 'weekly',
              onSelected: (_) => onChanged('weekly'),
            ),
            ChoiceChip(
              label: const Text('شهرياً'),
              selected: selectedRecurrence == 'monthly',
              onSelected: (_) => onChanged('monthly'),
            ),
          ],
        ),
      ],
    );
  }
}
