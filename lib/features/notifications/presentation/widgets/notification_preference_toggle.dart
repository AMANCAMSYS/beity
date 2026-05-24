import 'package:flutter/material.dart';

class NotificationPreferenceToggle extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NotificationPreferenceToggle({
    super.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(description),
        secondary: Icon(
          icon,
          color: value ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
