import 'package:intl/intl.dart';
import '../localization/app_localizations.dart';

class AppDateUtils {
  static String formatDate(DateTime date, [String locale = 'ar']) {
    return DateFormat('dd/MM/yyyy', locale).format(date);
  }
  
  static String formatDateTime(DateTime date, [String locale = 'ar']) {
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(date);
  }
  
  static String formatRelativeTime(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final langCode = l10n.locale.languageCode;
    
    if (difference.inDays > 7) {
      return formatDate(date, langCode);
    } else if (difference.inDays > 0) {
      return l10n.translate('time_days_ago', arguments: {'count': '${difference.inDays}'});
    } else if (difference.inHours > 0) {
      return l10n.translate('time_hours_ago', arguments: {'count': '${difference.inHours}'});
    } else if (difference.inMinutes > 0) {
      return l10n.translate('time_minutes_ago', arguments: {'count': '${difference.inMinutes}'});
    } else {
      return l10n.translate('time_now');
    }
  }
  
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
  
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
