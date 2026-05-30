import 'package:flutter/material.dart';

import 'package:beity/core/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../data/feedback_repository.dart';

class FeedbackBottomSheet extends StatefulWidget {
  final String? screenRoute;

  const FeedbackBottomSheet({super.key, this.screenRoute});

  static Future<void> show(BuildContext context) {
    // Capture active screen route name before pushing the modal route
    final route = ModalRoute.of(context)?.settings.name ?? 'unknown_screen';
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FeedbackBottomSheet(screenRoute: route),
    );
  }

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  String _feedbackType = 'bug';
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _error = context.translate('please_describe_issue'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repository = FeedbackRepository();
      await repository.submitFeedback(
        feedbackType: _feedbackType,
        description: _descriptionController.text.trim(),
        screenRoute: widget.screenRoute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الملاحظات. شكراً!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'فشل الإرسال. يرجى المحاولة مرة أخرى.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إرسال ملاحظات',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Semantics(
                button: true,
                label: 'Close feedback form',
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Type selector
          Semantics(
            label: 'Feedback type selector',
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'bug',
                  icon: Icon(Icons.bug_report_rounded),
                  label: Text('مشكلة'),
                ),
                ButtonSegment(
                  value: 'survey',
                  icon: Icon(Icons.lightbulb_rounded),
                  label: Text('اقتراح'),
                ),
              ],
              selected: {_feedbackType},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() {
                  _feedbackType = selection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Description field
          Semantics(
            label: 'Feedback description input',
            textField: true,
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'اصف ما حدث أو ما تريد أن تراه...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          if (widget.screenRoute != null && widget.screenRoute != 'unknown_screen') ...[
            Text(
              'الشاشة الحالية: ${widget.screenRoute}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'يتم إرفاق معلومات الجهاز وإصدار التطبيق وسجل العمليات تلقائياً',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Submit feedback',
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إرسال الملاحظات'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
     ),
    );
  }
}
