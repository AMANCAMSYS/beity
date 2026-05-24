import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app/config/env_config.dart';
import 'app/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/monitoring/monitoring_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

const bool isBeta = bool.fromEnvironment('BETA', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up immersive edge-to-edge system UI
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  
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
  
  // Set Arabic locale for timeago
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  
  runApp(
    const ProviderScope(
      child: BeityApp(),
    ),
  );
}

class BeityApp extends ConsumerStatefulWidget {
  const BeityApp({super.key});

  @override
  ConsumerState<BeityApp> createState() => _BeityAppState();
}

class _BeityAppState extends ConsumerState<BeityApp> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes (session expiry, server-side sign out)
    ref.listenManual(authStateProvider, (previous, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          // Session was terminated (expired, revoked, or server-side logout)
          // Navigate to login - the GoRouter redirect will handle this
          // but we also need to clear local state
          final authStateValue = ref.read(authNotifierProvider);
          if (authStateValue.value != null && !authStateValue.isLoading) {
            ref.read(authNotifierProvider.notifier).signOut().catchError((_) {});
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
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
      ),
    );
  }
}
