class BilingualTextHelper {
  static String getDisplayName({
    required String nameAr,
    String? nameEn,
    required String locale,
  }) {
    if (locale == 'en' && nameEn != null && nameEn.isNotEmpty) {
      return nameEn;
    }
    return nameAr;
  }

  static String getDisplayNameWithFallback({
    required String nameAr,
    String? nameEn,
    String locale = 'ar',
  }) {
    if (locale == 'en' && nameEn != null && nameEn.isNotEmpty) {
      return nameEn;
    }
    return nameAr;
  }
}
