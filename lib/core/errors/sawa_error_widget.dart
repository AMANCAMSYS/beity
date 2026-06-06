import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/shared_prefs_provider.dart';
import '../localization/app_localizations.dart';

class SawaErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const SawaErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    // Attempt to read language safely from SharedPreferences
    String lang = 'ar';
    try {
      lang = AppPreferences.instance.getString('settings.locale') ?? 'ar';
    } catch (_) {}

    final l10n = AppLocalizations(Locale(lang));
    final title = l10n.translate('error_occurred');
    final subtitle = l10n.translate('unexpected_error_retry');
    final buttonText = l10n.translate('back_to_home');

    final isRtl = ['ar', 'fa', 'he', 'ur'].contains(lang);
    final direction = isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Material(
      color: const Color(0xFF050807), // Dark Theme Background
      child: Directionality(
        textDirection: direction,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    try {
                      context.go('/');
                    } catch (_) {
                      // Fallback if router context is missing
                    }
                  },
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
