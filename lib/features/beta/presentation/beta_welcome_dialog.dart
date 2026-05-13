import 'package:flutter/material.dart';

import '../data/beta_preferences.dart';

class BetaWelcomeDialog extends StatelessWidget {
  const BetaWelcomeDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final shown = await BetaPreferences.isWelcomeShown();
    if (!shown && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const BetaWelcomeDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Semantics(
        label: 'Beity Beta welcome',
        child: const Text('بيتي - نسخة تجريبية'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك في نسخة بيتى التجريبية!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'أنت من أول من يجرّب تطبيقنا لإدارة المنزل.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'كيفية الإبلاغ عن مشكلة:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text('• اضغط على القائمة (☰) في أي شاشة'),
          const Text('• اختر "إرسال ملاحظات"'),
          const Text('• اصف ما حدث'),
          const SizedBox(height: 16),
          Text(
            'ملاحظاتك تساعدنا على التحسين!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
      actions: [
        Semantics(
          button: true,
          label: 'Got it button',
          child: FilledButton(
            onPressed: () async {
              await BetaPreferences.setWelcomeShown();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('فهمت!'),
          ),
        ),
      ],
    );
  }
}
