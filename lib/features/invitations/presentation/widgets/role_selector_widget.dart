import 'package:flutter/material.dart';

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
      items: const [
        DropdownMenuItem(
          value: 'admin',
          child: Text('مدير'),
        ),
        DropdownMenuItem(
          value: 'member',
          child: Text('عضو'),
        ),
        DropdownMenuItem(
          value: 'viewer',
          child: Text('مشاهد'),
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
        title: const Text(
          'تغيير الدور',
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل أنت متأكد من تغيير الدور إلى ${_getRoleName(newRole)}؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onChanged(newRole);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'member':
        return 'عضو';
      case 'viewer':
        return 'مشاهد';
      default:
        return role;
    }
  }
}
