import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String channel = 'tm.ranjith.trackmywork/notification';
  static const MethodChannel platform = MethodChannel(channel);

  // Use a single consistent ID for all activity tracking notifications
  static const int activityNotificationId = 1;

  // Track whether notification has been shown
  bool _notificationActive = false;

  // Store last notification content to avoid duplicate updates
  String? _lastNotificationTitle;
  String? _lastNotificationBody;
  DateTime _lastNotificationUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Minimum time between notification updates (in seconds)
  static const int minUpdateIntervalSeconds = 5;

  Future<void> init() async {
    debugPrint('Notification service initialized');
    // Request notification permissions
    await requestNotificationPermissions();
  }

  Future<void> requestNotificationPermissions() async {
    if (!Platform.isAndroid) {
      debugPrint('Notification permissions only handled on Android for now');
      return;
    }

    try {
      final result = await platform.invokeMethod('requestNotificationPermissions');
      debugPrint('Notification permissions result: $result');

      // Store that we've requested permissions
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasRequestedNotificationPermissions', true);
    } on PlatformException catch (e) {
      debugPrint('Failed to request notification permissions: ${e.message}');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) {
      // Default to true for platforms other than Android for now
      return true;
    }

    try {
      final bool enabled = await platform.invokeMethod('areNotificationsEnabled') ?? false;
      debugPrint('Notifications enabled: $enabled');
      return enabled;
    } on PlatformException catch (e) {
      debugPrint('Failed to check if notifications are enabled: ${e.message}');
      return false;
    }
  }

  Future<void> showActivityTrackingNotification({
    required String activityName,
    required String activityIcon,
    required Duration elapsed,
  }) async {
    if (!Platform.isAndroid) {
      // Skip notifications on non-Android platforms for now
      return;
    }

    // Check if notifications are enabled
    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      debugPrint('Notifications are disabled. Skipping notification.');
      return;
    }

    // Format the elapsed time
    final formattedTime = _formatElapsedTime(elapsed);
    final title = 'TrackMyWork';
    final body = 'Currently tracking: $activityName ($formattedTime)';

    try {
      debugPrint('Creating initial notification: $activityName, $formattedTime');
      await platform.invokeMethod('showNotification', {
        'id': activityNotificationId,
        'title': title,
        'body': body,
        'iconName': _getIconName(activityIcon),
        'ongoing': true,
      });

      // Store notification content to avoid duplicate updates
      _lastNotificationTitle = title;
      _lastNotificationBody = body;
      _lastNotificationUpdateTime = DateTime.now();

      // Mark notification as active
      _notificationActive = true;
    } on PlatformException catch (e) {
      debugPrint('Failed to show notification: ${e.message}');
    }
  }

  Future<void> updateNotificationContent({
    required String activityName,
    required String activityIcon,
    required Duration elapsed,
  }) async {
    if (!Platform.isAndroid) {
      // Skip notifications on non-Android platforms for now
      return;
    }

    // Check if notifications are enabled and active
    if (!_notificationActive) {
      debugPrint('No active notification to update. Creating new notification.');
      return showActivityTrackingNotification(
        activityName: activityName,
        activityIcon: activityIcon,
        elapsed: elapsed,
      );
    }

    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      debugPrint('Notifications are disabled. Skipping update.');
      return;
    }

    // Format the elapsed time
    final formattedTime = _formatElapsedTime(elapsed);
    final title = 'TrackMyWork';
    final body = 'Currently tracking: $activityName ($formattedTime)';

    // Check if content actually changed and if enough time has passed since last update
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastNotificationUpdateTime).inSeconds;

    if (body == _lastNotificationBody && title == _lastNotificationTitle) {
      // No change in content, skip update to reduce overhead
      return;
    }

    if (timeSinceLastUpdate < minUpdateIntervalSeconds) {
      // Too soon to update again, skip to reduce overhead
      // But still update our cached values for next comparison
      _lastNotificationTitle = title;
      _lastNotificationBody = body;
      return;
    }

    try {
      debugPrint('Updating notification: $activityName, $formattedTime');
      await platform.invokeMethod('updateNotificationContent', {
        'id': activityNotificationId,
        'title': title,
        'body': body,
        'iconName': _getIconName(activityIcon),
      });

      // Update stored values
      _lastNotificationTitle = title;
      _lastNotificationBody = body;
      _lastNotificationUpdateTime = now;
    } on PlatformException catch (e) {
      debugPrint('Failed to update notification content: ${e.message}');
    }
  }

  Future<void> cancelActivityTrackingNotification() async {
    if (!Platform.isAndroid) {
      // Skip for non-Android platforms
      return;
    }

    if (!_notificationActive) {
      // No notification to cancel
      return;
    }

    try {
      debugPrint('Canceling notification');
      await platform.invokeMethod('cancelNotification', {
        'id': activityNotificationId,
      });

      // Reset stored values
      _lastNotificationTitle = null;
      _lastNotificationBody = null;

      // Mark notification as inactive
      _notificationActive = false;
    } on PlatformException catch (e) {
      debugPrint('Failed to cancel notification: ${e.message}');
    }
  }

  // Helper method to format elapsed time consistently
  String _formatElapsedTime(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Convert Flutter icon names to native icon names
  String _getIconName(String iconName) {
    // This mapping can be extended based on your available native icons
    switch (iconName) {
      case 'work':
        return 'work';
      case 'computer':
        return 'computer';
      case 'school':
        return 'school';
      case 'fitness':
        return 'fitness';
      case 'book':
        return 'book';
      case 'movie':
        return 'movie';
      case 'music':
        return 'music';
      case 'food':
        return 'food';
      case 'shopping':
        return 'shopping';
      case 'travel':
        return 'travel';
      case 'home':
        return 'home';
      case 'brush':
        return 'brush';
      case 'code':
        return 'code';
      case 'sports':
        return 'sports';
      case 'game':
        return 'game';
      default:
        return 'access_time';
    }
  }
}