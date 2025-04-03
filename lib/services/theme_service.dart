import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends ChangeNotifier {
  // Theme constants
  static const String _themePreferenceKey = 'theme_preference';
  static const String _themeModeKey = 'theme_mode';
  
  // Available theme options
  final List<ThemeOption> themeOptions = [
    ThemeOption(
      name: 'Teal',
      primaryColor: Colors.teal,
      id: 'teal',
    ),
    ThemeOption(
      name: 'Blue',
      primaryColor: Colors.blue,
      id: 'blue',
    ),
    ThemeOption(
      name: 'Purple',
      primaryColor: Colors.purple,
      id: 'purple',
    ),
    ThemeOption(
      name: 'Orange',
      primaryColor: Colors.deepOrange,
      id: 'orange',
    ),
    ThemeOption(
      name: 'Green',
      primaryColor: Colors.green,
      id: 'green',
    ),
  ];
  
  // Current theme state
  String _currentThemeId = 'teal';
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getters
  String get currentThemeId => _currentThemeId;
  ThemeMode get themeMode => _themeMode;
  ThemeOption get currentThemeOption => 
      themeOptions.firstWhere((theme) => theme.id == _currentThemeId);
  
  // Initialize the theme service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved theme preference
    _currentThemeId = prefs.getString(_themePreferenceKey) ?? 'teal';
    
    // Load saved theme mode
    final savedThemeMode = prefs.getString(_themeModeKey);
    if (savedThemeMode != null) {
      switch (savedThemeMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
    
    notifyListeners();
  }
  
  // Set theme by ID
  Future<void> setTheme(String themeId) async {
    if (!themeOptions.any((theme) => theme.id == themeId)) return;
    
    _currentThemeId = themeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeId);
    notifyListeners();
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }
    
    await prefs.setString(_themeModeKey, modeString);
    notifyListeners();
  }
  
  // Get light theme data
  ThemeData getLightTheme(BuildContext context) {
    final primaryColor = currentThemeOption.primaryColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );
    
    // Create a base text theme with inherit: false
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor.withOpacity(0.1),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  // Get dark theme data
  ThemeData getDarkTheme(BuildContext context) {
    final primaryColor = currentThemeOption.primaryColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor.shade300,
      onPrimary: Colors.black,
      secondary: primaryColor.shade200,
      background: const Color(0xFF1E1E1E),
      surface: const Color(0xFF2C2C2C),
      onBackground: Colors.white,
      onSurface: Colors.white.withOpacity(0.87),
    );
    
    // Create a base text theme with inherit: false
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: Colors.white.withOpacity(0.87),
      displayColor: Colors.white,
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor.shade200,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor.shade300,
        foregroundColor: Colors.black,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        color: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      iconTheme: IconThemeData(
        color: primaryColor.shade200,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.2),
      ),
    );
  }
}

// Theme option model
class ThemeOption {
  final String name;
  final MaterialColor primaryColor;
  final String id;
  
  ThemeOption({
    required this.name,
    required this.primaryColor,
    required this.id,
  });
}
