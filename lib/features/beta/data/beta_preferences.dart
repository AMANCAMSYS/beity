import 'package:beity/core/services/shared_prefs_provider.dart';

class BetaPreferences {
  static const String _welcomeShownKey = 'beta_welcome_shown';
  static const String _surveyShownKey = 'satisfaction_survey_shown';

  static Future<bool> isWelcomeShown() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_welcomeShownKey) ?? false;
  }

  static Future<void> setWelcomeShown() async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_welcomeShownKey, true);
  }

  static Future<bool> isSurveyShown() async {
    final prefs = AppPreferences.instance;
    return prefs.getBool(_surveyShownKey) ?? false;
  }

  static Future<void> setSurveyShown() async {
    final prefs = AppPreferences.instance;
    await prefs.setBool(_surveyShownKey, true);
  }
}
