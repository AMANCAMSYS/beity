import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/core/localization/app_localizations.dart';

class NoActiveHomeWidget extends StatelessWidget {
  const NoActiveHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.translate('app_name'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.translate('no_active_home'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.translate('select_or_create_home'),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/homes'),
              icon: const Icon(Icons.list),
              label: Text(context.translate('manage_homes')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/homes/create'),
              icon: const Icon(Icons.add),
              label: Text(context.translate('create_home_button')),
            ),
          ],
        ),
      ),
    );
  }
}
