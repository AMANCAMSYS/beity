import 'package:shared_preferences/shared_preferences.dart';

class BetaPreferences {
  static const String _welcomeShownKey = 'beta_welcome_shown';
  static const String _surveyShownKey = 'satisfaction_survey_shown';

  static Future<bool> isWelcomeShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeShownKey) ?? false;
  }

  static Future<void> setWelcomeShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeShownKey, true);
  }

  static Future<bool> isSurveyShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_surveyShownKey) ?? false;
  }

  static Future<void> setSurveyShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_surveyShownKey, true);
  }
}
