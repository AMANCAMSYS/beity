import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Clarifying questions UI with quick option buttons.
class AiClarifyingQuestions extends StatelessWidget {
  final List<String> questions;
  final List<String> quickOptions;
  final ValueChanged<String> onOptionSelected;

  const AiClarifyingQuestions({
    super.key,
    required this.questions,
    required this.quickOptions,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.help_outline_rounded, color: AppColors.info, size: 22),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'نحتاج بعض التفاصيل' : 'We need some details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Questions
            ...questions.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16)),
                  Expanded(
                    child: Text(
                      q,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),

            if (quickOptions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                isArabic ? 'أو اختر سريعًا:' : 'Or choose quickly:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickOptions.map((option) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onOptionSelected(option),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primaryLight.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
