import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

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
        label: 'SAWA Beta welcome',
        child: Text(context.translate('beta_welcome_title')),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.translate('beta_welcome_greeting'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.translate('beta_welcome_desc'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            context.translate('beta_how_to_report'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(context.translate('beta_step_1')),
          Text(context.translate('beta_step_2')),
          Text(context.translate('beta_step_3')),
          const SizedBox(height: 16),
          Text(
            context.translate('beta_feedback_helps'),
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
            child: Text(context.translate('got_it')),
          ),
        ),
      ],
    );
  }
}
