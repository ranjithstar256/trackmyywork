import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String activityTrackingChannelId = 'activity_tracking_channel';
  static const String activityTrackingChannelName = 'Activity Tracking';
  static const String activityTrackingChannelDescription = 'Shows currently tracked activity';
  
  static const int activityNotificationId = 1;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {},
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        // Handle notification tap
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            activityTrackingChannelId,
            activityTrackingChannelName,
            description: activityTrackingChannelDescription,
            importance: Importance.high,
          ));
    }
  }

  Future<void> showActivityTrackingNotification({
    required String activityName,
    required String activityIcon,
    required Duration elapsed,
  }) async {
    // Format the elapsed time
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final formattedTime = 
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    // Get the icon resource for the notification
    final IconData iconData = _getIconData(activityIcon);
    String iconName = 'access_time';
    
    // Map the icon to a system icon name
    if (iconData == Icons.work) iconName = 'work';
    else if (iconData == Icons.computer) iconName = 'computer';
    else if (iconData == Icons.school) iconName = 'school';
    else if (iconData == Icons.fitness_center) iconName = 'fitness_center';
    else if (iconData == Icons.book) iconName = 'book';
    else if (iconData == Icons.movie) iconName = 'movie';
    else if (iconData == Icons.music_note) iconName = 'music_note';
    else if (iconData == Icons.restaurant) iconName = 'restaurant';
    else if (iconData == Icons.shopping_cart) iconName = 'shopping_cart';
    else if (iconData == Icons.flight) iconName = 'flight';
    else if (iconData == Icons.home) iconName = 'home';
    else if (iconData == Icons.brush) iconName = 'brush';
    else if (iconData == Icons.code) iconName = 'code';
    else if (iconData == Icons.sports) iconName = 'sports';
    else if (iconData == Icons.sports_esports) iconName = 'sports_esports';
    
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      activityTrackingChannelId,
      activityTrackingChannelName,
      channelDescription: activityTrackingChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      category: 'service',
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'stop',
          'Stop',
          icon: DrawableResourceAndroidBitmap('ic_stop'),
        ),
      ],
    );
    
    final IOSNotificationDetails iOSPlatformChannelSpecifics =
        IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      activityNotificationId,
      'TrackMyWork',
      'Currently tracking: $activityName ($formattedTime)',
      platformChannelSpecifics,
      payload: 'activity_tracking',
    );
  }

  Future<void> cancelActivityTrackingNotification() async {
    await flutterLocalNotificationsPlugin.cancel(activityNotificationId);
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'computer':
        return Icons.computer;
      case 'school':
        return Icons.school;
      case 'fitness':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'movie':
        return Icons.movie;
      case 'music':
        return Icons.music_note;
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_cart;
      case 'travel':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'brush':
        return Icons.brush;
      case 'code':
        return Icons.code;
      case 'sports':
        return Icons.sports;
      case 'game':
        return Icons.sports_esports;
      default:
        return Icons.access_time;
    }
  }
}
