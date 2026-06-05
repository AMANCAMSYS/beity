class AppConfig {
  static const String appName = 'SAWA';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.sawa.sawa';
  
  // API Configuration
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30000;
  
  // Cache Configuration
  static const int cacheMaxAge = 7; // days
  static const int cacheMaxSize = 100; // MB
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';
}
