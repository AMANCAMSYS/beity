import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class RoleSelectorWidget extends StatelessWidget {
  final String currentRole;
  final Function(String) onChanged;

  const RoleSelectorWidget({
    super.key,
    required this.currentRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentRole,
      items: [
        DropdownMenuItem(
          value: 'admin',
          child: Text(context.translate('admin')),
        ),
        DropdownMenuItem(
          value: 'member',
          child: Text(context.translate('member')),
        ),
        DropdownMenuItem(
          value: 'viewer',
          child: Text(context.translate('viewer')),
        ),
      ],
      onChanged: (value) {
        if (value != null && value != currentRole) {
          _showConfirmationDialog(context, value);
        }
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, String newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.translate('change_role'),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          context.translate('confirm_change_role', arguments: {'role': _getRoleName(context, newRole)}),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onChanged(newRole);
            },
            child: Text(context.translate('confirm')),
          ),
        ],
      ),
    );
  }

  String _getRoleName(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        return context.translate('admin');
      case 'member':
        return context.translate('member');
      case 'viewer':
        return context.translate('viewer');
      default:
        return role;
    }
  }
}
