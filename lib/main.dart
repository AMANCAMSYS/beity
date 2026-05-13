import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app/config/env_config.dart';
import 'app/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/monitoring/monitoring_service.dart';
import 'firebase_options.dart';

const bool isBeta = bool.fromEnvironment('BETA', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Crashlytics monitoring
  await MonitoringService().initialize();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Notification Service
  await NotificationService.initialize();
  
  // Set navigator key for deep linking
  NotificationService.setNavigatorKey(appNavigatorKey);
  
  runApp(
    const ProviderScope(
      child: BeityApp(),
    ),
  );
}

class BeityApp extends ConsumerWidget {
  const BeityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: EnvConfig.isDebug,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
