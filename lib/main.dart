import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:trackmywork/screens/SplashScreen.dart';
import 'services/time_tracking_service.dart';
import 'services/background_service.dart';
import 'services/premium_features_service.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';
import 'services/theme_service.dart';
import 'services/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/add_activity_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/intro_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Global error handler
Future<void> reportError(dynamic error, dynamic stackTrace) async {
  // Implement error reporting logic here (e.g., Firebase Crashlytics)
  debugPrint('Caught error: $error');
  debugPrint('Stack trace: $stackTrace');
}

// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Catch any errors that occur during initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    reportError(details.exception, details.stack);
  };

  // Set preferred orientation early
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Show loading screen first, then initialize services
  runApp(const SplashScreen());

  // Initialize services
  try {
    await initializeServices();
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    reportError(e, stackTrace);
  }
}

Future<void> initializeServices() async {
  // Initialize background service
  try {
    await BackgroundService.initializeService();
  } catch (e) {
    debugPrint('Background service initialization skipped: $e');
  }

  // Initialize AdMob
  await MobileAds.instance.initialize();

  // Initialize database
  final databaseHelper = DatabaseHelper();
  await databaseHelper.initDatabase();
  
  // Initialize services
  final timeTrackingService = TimeTrackingService();
  final subscriptionService = SubscriptionService();
  final adService = AdService();
  final themeService = ThemeService();

  // Initialize all services in parallel
  await Future.wait([
    timeTrackingService.init(),
    subscriptionService.init(),
    adService.init(),
    themeService.init(),
  ]);

  // Check if this is the first launch
  final prefs = await SharedPreferences.getInstance();
  final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

  // Now launch the main app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => timeTrackingService),
        ChangeNotifierProvider(create: (_) => subscriptionService),
        ChangeNotifierProvider(create: (_) => adService),
        ChangeNotifierProvider(create: (_) => themeService),
      ],
      child: MyApp(hasSeenIntro: hasSeenIntro),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenIntro;

  const MyApp({super.key, required this.hasSeenIntro});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TrackMyWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeService.currentThemeOption.primaryColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeService.currentThemeOption.primaryColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: themeService.themeMode,
      initialRoute: hasSeenIntro ? '/' : '/intro',
      routes: {
        '/': (context) => const HomeScreen(),
        '/intro': (context) => const IntroScreen(),
        '/add_activity': (context) => const AddActivityScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
      },
    );
  }
}
