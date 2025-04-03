// This file has been updated to implement activity tracking with proper timer functionality
// Notifications temporarily disabled to focus on timer functionality

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  static const String activeActivityIdKey = 'active_activity_id';
  static const String activeActivityNameKey = 'active_activity_name';
  static const String activeActivityIconKey = 'active_activity_icon';
  static const String activeActivityStartTimeKey = 'active_activity_start_time';

  static Timer? _timer;
  static Duration _elapsed = Duration.zero;
  static final StreamController<Duration> _elapsedStreamController = 
      StreamController<Duration>.broadcast();

  static Stream<Duration> get elapsedStream => _elapsedStreamController.stream;
  static Duration get elapsed => _elapsed;

  static Future<void> initializeService() async {
    debugPrint('Background service initialized');
    
    // Check if there's an active activity and resume the timer
    await _checkForActiveActivity();
  }

  static Future<void> _checkForActiveActivity() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if there's an active activity
    final activeActivityId = prefs.getString(activeActivityIdKey);
    
    if (activeActivityId != null) {
      // Get the start time as an int (milliseconds since epoch)
      final startTimeMillis = prefs.getInt(activeActivityStartTimeKey) ?? 0;
      
      if (startTimeMillis > 0) {
        // Calculate elapsed time
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedMillis = now - startTimeMillis;
        _elapsed = Duration(milliseconds: elapsedMillis);
        
        // Immediately emit the current elapsed time to any listeners
        _elapsedStreamController.add(_elapsed);
        
        // Start the timer to update elapsed time
        _startElapsedTimer();
        
        debugPrint('Resumed timer with elapsed time: ${_elapsed.inSeconds} seconds');
      }
    }
  }

  static Future<void> startTimer(String activityId, String activityName, String activityIcon) async {
    // Stop any existing timer
    _timer?.cancel();
    
    final prefs = await SharedPreferences.getInstance();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Save activity details
    await prefs.setString(activeActivityIdKey, activityId);
    await prefs.setString(activeActivityNameKey, activityName);
    await prefs.setString(activeActivityIconKey, activityIcon);
    await prefs.setInt(activeActivityStartTimeKey, startTime);
    
    // Reset elapsed time
    _elapsed = Duration.zero;
    
    // Immediately emit the reset elapsed time
    _elapsedStreamController.add(_elapsed);
    
    // Start the timer
    _startElapsedTimer();
    
    debugPrint('Started timer for activity: $activityId');
  }
  
  static void _startElapsedTimer() {
    // Cancel any existing timer to avoid duplicates
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed = _elapsed + const Duration(seconds: 1);
      _elapsedStreamController.add(_elapsed);
      
      debugPrint('Timer tick: ${_elapsed.inSeconds} seconds');
    });
  }

  static Future<void> stopTimer() async {
    _timer?.cancel();
    _timer = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(activeActivityIdKey);
    await prefs.remove(activeActivityNameKey);
    await prefs.remove(activeActivityIconKey);
    await prefs.remove(activeActivityStartTimeKey);
    
    _elapsed = Duration.zero;
    _elapsedStreamController.add(_elapsed);
    
    debugPrint('Stopped timer');
  }

  static Future<Map<String, dynamic>?> getActiveActivityDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final activityId = prefs.getString(activeActivityIdKey);
    
    if (activityId == null) {
      return null;
    }
    
    final activityName = prefs.getString(activeActivityNameKey) ?? 'Unknown';
    final activityIcon = prefs.getString(activeActivityIconKey) ?? 'work';
    final startTimeMillis = prefs.getInt(activeActivityStartTimeKey) ?? 0;
    
    if (startTimeMillis == 0) {
      return null;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMillis = now - startTimeMillis;
    final elapsed = Duration(milliseconds: elapsedMillis);
    
    return {
      'id': activityId,
      'name': activityName,
      'icon': activityIcon,
      'startTime': startTimeMillis,
      'elapsed': elapsed,
    };
  }
  
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
