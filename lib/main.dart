import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/time_tracking_service.dart';
import 'services/background_service.dart';
import 'services/premium_features_service.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_activity_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
  try {
    await BackgroundService.initializeService();
  } catch (e) {
    debugPrint('Background service initialization skipped: $e');
  }
  
  // Initialize TimeTrackingService
  final timeTrackingService = TimeTrackingService();
  await timeTrackingService.init();
  
  // Initialize SubscriptionService
  final subscriptionService = SubscriptionService();
  await subscriptionService.init();
  
  // Initialize AdService
  final adService = AdService();
  await adService.init();
  
  // Initialize ThemeService
  final themeService = ThemeService();
  await themeService.init();
  
  // Set preferred orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => timeTrackingService),
        ChangeNotifierProvider(create: (_) => subscriptionService),
        ChangeNotifierProvider(create: (_) => adService),
        ChangeNotifierProvider(create: (_) => themeService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/add_activity': (context) => const AddActivityScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
      },
    );
  }
}
