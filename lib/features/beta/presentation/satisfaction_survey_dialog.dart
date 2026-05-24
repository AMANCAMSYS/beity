import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/star_rating.dart';
import '../data/beta_preferences.dart';
import '../data/feedback_repository.dart';

class SatisfactionSurveyDialog extends StatefulWidget {
  const SatisfactionSurveyDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final shown = await BetaPreferences.isSurveyShown();
    if (!shown && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SatisfactionSurveyDialog(),
      );
    }
  }

  @override
  State<SatisfactionSurveyDialog> createState() => _SatisfactionSurveyDialogState();
}

class _SatisfactionSurveyDialogState extends State<SatisfactionSurveyDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تقييم'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = FeedbackRepository();
      await repository.submitFeedback(
        feedbackType: 'survey',
        description: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : 'No comment',
        starRating: _rating,
      );

      await BetaPreferences.setSurveyShown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شكراً لملاحظاتك!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الإرسال. يرجى المحاولة مرة أخرى.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _skip() async {
    await BetaPreferences.setSurveyShown();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Semantics(
        label: 'Shopping experience survey',
        child: const Text('كيف كانت تجربة التسوق؟'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Star rating, currently $_rating out of 5',
            child: StarRating(
              initialRating: _rating,
              onRatingChanged: (rating) {
                setState(() => _rating = rating);
              },
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Additional comments input',
            textField: true,
            child: TextFormField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'أي ملاحظات إضافية؟ (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _skip,
          child: const Text('تخطي'),
        ),
        Semantics(
          button: true,
          label: 'Submit survey',
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إرسال'),
          ),
        ),
      ],
    );
  }
}
