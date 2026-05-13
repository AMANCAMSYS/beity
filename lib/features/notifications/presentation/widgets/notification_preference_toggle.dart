import 'package:flutter/material.dart';

import '../../domain/entities/notification_preference.dart';

class NotificationPreferenceToggle extends StatelessWidget {
  final NotificationPreference preference;
  final ValueChanged<bool> onChanged;

  const NotificationPreferenceToggle({
    super.key,
    required this.preference,
    required this.onChanged,
  });

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'shopping_list':
        return 'Shopping List Updates';
      case 'home_activity':
        return 'Home Activity';
      case 'invitation':
        return 'Invitations';
      default:
        return category;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'shopping_list':
        return 'Get notified when items are added, updated, or purchased';
      case 'home_activity':
        return 'Get notified when new members join your home';
      case 'invitation':
        return 'Get notified when you receive home invitations';
      default:
        return '';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'shopping_list':
        return Icons.shopping_cart;
      case 'home_activity':
        return Icons.home;
      case 'invitation':
        return Icons.mail;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(
          _getCategoryLabel(preference.category),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(_getCategoryDescription(preference.category)),
        secondary: Icon(
          _getCategoryIcon(preference.category),
          color: preference.enabled ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        value: preference.enabled,
        onChanged: onChanged,
      ),
    );
  }
}
