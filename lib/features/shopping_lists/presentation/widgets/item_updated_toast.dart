import 'package:flutter/material.dart';

class ItemUpdatedToast {
  static void show(BuildContext context, {required String updatedBy}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.sync, color: theme.colorScheme.onSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic 
                    ? 'تم التحديث بواسطة $updatedBy'
                    : 'Updated by $updatedBy',
                style: TextStyle(color: theme.colorScheme.onSecondary),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.secondary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
