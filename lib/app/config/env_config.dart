import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get appName => dotenv.env['APP_NAME'] ?? 'Beity';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
  static bool get isDebug => dotenv.env['DEBUG_MODE'] == 'true';
  static bool get isProduction => appEnv == 'production';
  static String get firebaseVapidKey => dotenv.env['FIREBASE_VAPID_KEY'] ?? '';
}
