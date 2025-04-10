import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:trackmywork/services/time_tracking_service.dart';
import '../main.dart';
import 'notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String channel = 'tm.ranjith.trackmywork/background';
  static const MethodChannel platform = MethodChannel(channel);
  static const String stopTrackingChannel = 'STOP_TRACKING';
  static const BasicMessageChannel<String> stopTrackingMessageChannel =
      BasicMessageChannel<String>(stopTrackingChannel, StringCodec());

  // Use a single consistent ID for all activity tracking notifications
  static const int activityNotificationId = 1;

  // Track whether notification has been shown
  bool _notificationActive = false;

  // Store last notification content to avoid duplicate updates
  String? _lastNotificationTitle;
  String? _lastNotificationBody;
  DateTime _lastNotificationUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Minimum time between notimm,fication updates (in seconds)
  static const int minUpdateIntervalSeconds = 5;

  // Stream controllers for UI and notification updates
  final StreamController<Duration> _uiUpdateController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _notificationUpdateController =
      StreamController<Duration>.broadcast();

  // Stream subscriptions
  StreamSubscription? _uiUpdateSubscription;
  StreamSubscription? _notificationUpdateSubscription;

  // Dynamic update intervals based on battery optimization
  Duration _uiUpdateInterval = const Duration(seconds: 1);
  Duration _notificationUpdateInterval = const Duration(seconds: 15);

  // Track elapsed time
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // Track active activity
  String? _activeActivityId;
  String? _activeActivityName;
  String? _activeActivityIcon;

  // Track error count and last error time
  int _errorCount = 0;
  static const int maxErrors = 3;
  DateTime? _lastErrorTime;
  static const Duration errorResetDuration = Duration(minutes: 5);

  // Track if we need to show initial notification
  bool _needInitialNotification = true;

  // Battery optimization state
  bool _isBatteryOptimized = false;

  // Stream getters
  Stream<Duration> get uiUpdateStream => _uiUpdateController.stream;
  Stream<Duration> get notificationUpdateStream =>
      _notificationUpdateController.stream;
  Stream<Duration> get elapsedStream => _uiUpdateController.stream;
  Duration get elapsed => _elapsed;

  static Future<void> initializeService() async {
    debugPrint('Background service initialized');
    await NotificationService().requestNotificationPermissions();

    // Check battery optimization status
    await _instance._checkBatteryOptimization();

    stopTrackingMessageChannel.setMessageHandler((String? message) async {
      if (message == 'STOP_TRACKING') {
        debugPrint('Received STOP_TRACKING message from native code');
        await _instance.stopTimer();
        return 'Message received';
      }
      return 'Unknown message';
    });
  }

  Future<void> _checkBatteryOptimization() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Theme.of(navigatorKey.currentContext!).platform ==
          TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;

        // Check battery level as a proxy for battery optimization
        // Lower battery levels might indicate battery optimization is active
        final batteryLevel = await _getBatteryLevel();
        _isBatteryOptimized = batteryLevel < 20;

        // Adjust intervals based on battery optimization
        if (_isBatteryOptimized) {
          _uiUpdateInterval = const Duration(seconds: 5);
          _notificationUpdateInterval = const Duration(seconds: 30);
          debugPrint(
              'Battery level low ($batteryLevel%), using optimized intervals');
        } else {
          debugPrint(
              'Battery level normal ($batteryLevel%), using standard intervals');
        }
      }
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
    }
  }

  Future<int> _getBatteryLevel() async {
    try {
      const platform = MethodChannel('tm.ranjith.trackmywork/battery');
      final int batteryLevel = await platform.invokeMethod('getBatteryLevel');
      return batteryLevel;
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      return 100; // Default to full battery if we can't get the level
    }
  }

  Future<void> startTimer(
      String activityId, String activityName, String activityIcon) async {
    debugPrint('Starting timer for activity: $activityId');

    // Store active activity details
    _activeActivityId = activityId;
    _activeActivityName = activityName;
    _activeActivityIcon = activityIcon;

    // Reset error count
    _errorCount = 0;
    _lastErrorTime = null;

    // Reset elapsed time
    _elapsed = Duration.zero;

    // Set start time
    _startTime = DateTime.now();

    // Cancel existing timer if any
    _timer?.cancel();

    // Cancel existing subscriptions if any
    await _uiUpdateSubscription?.cancel();
    await _notificationUpdateSubscription?.cancel();

    // Start UI update stream with dynamic interval
    _uiUpdateSubscription = Stream.periodic(_uiUpdateInterval).listen((_) {
      _updateElapsedTime();
      _uiUpdateController.add(_elapsed);
    });

    // Start notification update stream with dynamic interval
    _notificationUpdateSubscription =
        Stream.periodic(_notificationUpdateInterval).listen((_) {
      _updateElapsedTime();
      _updateNotification();
    });

    // Show initial notification
    if (_needInitialNotification) {
      await _showNotification();
      _needInitialNotification = false;
    }

    // Store active activity details in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeActivityId', activityId);
    await prefs.setString('activeActivityName', activityName);
    await prefs.setString('activeActivityIcon', activityIcon);
    await prefs.setString('startTime', _startTime!.toIso8601String());
  }

  Future<void> stopTimer() async {
    debugPrint('Stopping timer');

    // Cancel timer
    _timer?.cancel();
    _timer = null;

    // Cancel subscriptions
    await _uiUpdateSubscription?.cancel();
    await _notificationUpdateSubscription?.cancel();

    // Reset elapsed time
    _elapsed = Duration.zero;

    // Reset start time
    _startTime = null;

    // Reset active activity
    _activeActivityId = null;
    _activeActivityName = null;
    _activeActivityIcon = null;

    // Reset error count
    _errorCount = 0;

    // Reset notification flag
    _needInitialNotification = true;

    // Cancel notification
    await _cancelNotification();

    // Clear active activity details from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeActivityId');
    await prefs.remove('activeActivityName');
    await prefs.remove('activeActivityIcon');
    await prefs.remove('startTime');

    // Close stream controllers
    await _uiUpdateController.close();
    await _notificationUpdateController.close();



    debugPrint('Timer stopped');

    final timeTrackingService = Provider.of<TimeTrackingService>(navigatorKey.currentContext!, listen: false);

    // Update the time tracking service
    timeTrackingService.stopCurrentActivity();

  }

  void _updateElapsedTime() {
    if (_startTime != null) {
      _elapsed = DateTime.now().difference(_startTime!);
    }
  }

  Future<void> _showNotification() async {
    if (_activeActivityName == null || _activeActivityIcon == null) {
      debugPrint('Cannot show notification: missing activity details');
      return;
    }

    try {
      await NotificationService().showActivityTrackingNotification(
        activityName: _activeActivityName!,
        activityIcon: _activeActivityIcon!,
        elapsed: _elapsed,
      );

      // Reset error count on success
      _errorCount = 0;
    } catch (e) {
      debugPrint('Error showing notification: $e');
      _handleError();
    }
  }

  Future<void> _updateNotification() async {
    if (_activeActivityName == null || _activeActivityIcon == null) {
      debugPrint('Cannot update notification: missing activity details');
      return;
    }

    try {
      await NotificationService().updateNotificationContent(
        activityName: _activeActivityName!,
        activityIcon: _activeActivityIcon!,
        elapsed: _elapsed,
      );

      // Reset error count on success
      _errorCount = 0;
    } catch (e) {
      debugPrint('Error updating notification: $e');
      _handleError();
    }
  }

  Future<void> _cancelNotification() async {
    try {
      await NotificationService().cancelActivityTrackingNotification();

      // Reset error count on success
      _errorCount = 0;
    } catch (e) {
      debugPrint('Error canceling notification: $e');
      _handleError();
    }
  }

  void _handleError() {
    final now = DateTime.now();

    // Reset error count if enough time has passed
    if (_lastErrorTime != null &&
        now.difference(_lastErrorTime!) > errorResetDuration) {
      _errorCount = 0;
    }

    _errorCount++;
    _lastErrorTime = now;

    if (_errorCount >= maxErrors) {
      debugPrint('Too many errors, attempting to restart timer');
      _restartTimer();
    }
  }

  Future<void> _restartTimer() async {
    debugPrint('Restarting timer');

    // Stop current timer
    await stopTimer();

    // Start new timer with same activity
    if (_activeActivityId != null &&
        _activeActivityName != null &&
        _activeActivityIcon != null) {
      await startTimer(
          _activeActivityId!, _activeActivityName!, _activeActivityIcon!);
    }
  }

  // Changed from static to instance method
  Future<Map<String, dynamic>?> getActiveActivityDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final activityId = prefs.getString('activeActivityId');
      final activityName = prefs.getString('activeActivityName');
      final activityIcon = prefs.getString('activeActivityIcon');
      final startTimeStr = prefs.getString('startTime');

      if (activityId == null ||
          activityName == null ||
          activityIcon == null ||
          startTimeStr == null) {
        return null;
      }

      final startTime = DateTime.parse(startTimeStr);
      final elapsed = DateTime.now().difference(startTime);

      return {
        'id': activityId,
        'name': activityName,
        'icon': activityIcon,
        'elapsed': elapsed,
      };
    } catch (e) {
      debugPrint('Error getting active activity details: $e');
      return null;
    }
  }

  // Helper method to format elapsed time consistently
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // Enhanced dispose method
  Future<void> dispose() async {
    await _uiUpdateController.close();
    await _notificationUpdateController.close();
    await _uiUpdateSubscription?.cancel();
    await _notificationUpdateSubscription?.cancel();
    _timer?.cancel();

    // Clear any stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeActivityId');
    await prefs.remove('activeActivityName');
    await prefs.remove('activeActivityIcon');
    await prefs.remove('startTime');
  }
}
