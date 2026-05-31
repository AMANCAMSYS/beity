import 'dart:math' as math;
import 'dart:ui';

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
import 'core/services/sync_coordinator.dart';
import 'core/monitoring/monitoring_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/settings/presentation/providers/app_settings_provider.dart';
import 'features/homes/presentation/providers/homes_provider.dart';
import 'core/services/shared_prefs_provider.dart';
import 'core/errors/beity_error_widget.dart';
import 'firebase_options.dart';

const bool isBeta = bool.fromEnvironment('BETA', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences Singleton synchronously (required for local cache layout on first frame)
  await AppPreferences.init();

  // 2. Load environment variables
  await dotenv.load(fileName: '.env');

  // 3. Initialize Supabase (required by GoRouter immediately in BeityApp build)
  await SupabaseService.initialize();

  // 4. Keep app content inside the visible system-safe area.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF050807),
      systemNavigationBarDividerColor: Color(0xFF050807),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 5. Initialize secondary, background-friendly services asynchronously.
  // This completely unblocks the UI startup flow, rendering the dashboard instantly!
  _initializeBackgroundServices();

  // Set Arabic locale for timeago
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // Setup Global Error Boundary UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return BeityErrorWidget(details: details);
  };

  runApp(const ProviderScope(child: BeityApp()));
}

/// Initializes auxiliary third-party services in the background without holding up the first frame UI paint.
Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Initialize Crashlytics monitoring
    await MonitoringService().initialize();

    // Catch all uncaught async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      MonitoringService().logError(error, stack, reason: 'Uncaught platform error', fatal: true);
      return true;
    };

    // Initialize Notification Service
    await NotificationService.initialize();

    // Set navigator key for deep linking
    NotificationService.setNavigatorKey(appNavigatorKey);
  } catch (e, stack) {
    assert(() {
      debugPrint('Failed to initialize background services: $e\n$stack');
      return true;
    }());
  }
}

class BeityApp extends ConsumerStatefulWidget {
  const BeityApp({super.key});

  @override
  ConsumerState<BeityApp> createState() => _BeityAppState();
}

class _BeityAppState extends ConsumerState<BeityApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for auth state changes (session expiry, server-side sign out)
    ref.listenManual(authStateProvider, (previous, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          // Session was terminated (expired, revoked, or server-side logout)
          // Navigate to login - the GoRouter redirect will handle this
          // but we also need to clear local state
          final authStateValue = ref.read(authNotifierProvider);
          if (authStateValue.value != null && !authStateValue.isLoading) {
            ref
                .read(authNotifierProvider.notifier)
                .signOut()
                .catchError((_) {});
          }
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final activeHomeId = ref.read(cachedActiveHomeIdProvider);
      if (activeHomeId != null && activeHomeId.isNotEmpty) {
        ref.read(syncCoordinatorProvider.notifier).smartResumeSync(activeHomeId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsProvider);

    return Directionality(
      textDirection: settings.locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: MaterialApp.router(
        title: EnvConfig.appName,
        debugShowCheckedModeBanner: EnvConfig.isDebug,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        routerConfig: router,
        locale: settings.locale,
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('en', 'US'),
          Locale('tr', 'TR'),
        ],
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final safePadding = mediaQuery.padding.copyWith(
            bottom: math.max(
              mediaQuery.padding.bottom,
              mediaQuery.viewPadding.bottom,
            ),
          );

          return MediaQuery(
            data: mediaQuery.copyWith(
              padding: safePadding,
              textScaler: TextScaler.linear(settings.fontSizeScale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
