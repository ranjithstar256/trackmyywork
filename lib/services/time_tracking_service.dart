import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../models/time_entry.dart';
import 'background_service.dart';

class Activity {
  final String id;
  final String name;
  final String color;
  final String icon;
  final bool isDefault;

  Activity({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.isDefault = false,
  });

  Activity copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    bool? isDefault,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'isDefault': isDefault,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class TimeEntry {
  final String id;
  final String activityId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? note;

  TimeEntry({
    required this.id,
    required this.activityId,
    required this.startTime,
    this.endTime,
    this.note,
  });

  TimeEntry copyWith({
    String? id,
    String? activityId,
    DateTime? startTime,
    DateTime? endTime,
    String? note,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
    );
  }

  Duration get duration {
    if (endTime == null) {
      return Duration.zero;
    }
    return endTime!.difference(startTime);
  }

  bool get isActive => endTime == null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'note': note,
    };
  }

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'],
      activityId: json['activityId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      note: json['note'],
    );
  }
}

class TimeTrackingService extends ChangeNotifier {
  late SharedPreferences _prefs;
  
  List<Activity> _activities = [];
  List<TimeEntry> _timeEntries = [];
  
  String? _currentActivityId;
  
  List<Activity> get activities => _activities;
  List<TimeEntry> get timeEntries => _timeEntries;
  String? get currentActivityId => _currentActivityId;
  
  bool get isTracking => _currentActivityId != null;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize background service
    await BackgroundService.initializeService();
    
    // Load activities
    final activitiesJson = _prefs.getStringList('activities') ?? [];
    _activities = activitiesJson
        .map((json) => Activity.fromJson(jsonDecode(json)))
        .toList();
    
    // Load time entries
    final timeEntriesJson = _prefs.getStringList('timeEntries') ?? [];
    _timeEntries = timeEntriesJson
        .map((json) => TimeEntry.fromJson(jsonDecode(json)))
        .toList();
    
    // Create default activities if none exist
    if (_activities.isEmpty) {
      await _createDefaultActivities();
    }
    
    // Check for any active time entries from background service
    await _checkForActiveTimeEntries();
  }
  
  Future<void> _createDefaultActivities() async {
    final workActivity = Activity(
      id: const Uuid().v4(),
      name: 'Work',
      color: '0xFF4CAF50',
      icon: 'work',
      isDefault: true,
    );
    
    final breakActivity = Activity(
      id: const Uuid().v4(),
      name: 'Break',
      color: '0xFF2196F3',
      icon: 'coffee',
      isDefault: true,
    );
    
    _activities.add(workActivity);
    _activities.add(breakActivity);
    
    await _saveActivities();
  }
  
  Future<void> _saveActivities() async {
    final activitiesJson = _activities
        .map((activity) => jsonEncode(activity.toJson()))
        .toList();
    
    await _prefs.setStringList('activities', activitiesJson);
  }
  
  Future<void> _saveTimeEntries() async {
    final timeEntriesJson = _timeEntries
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    
    await _prefs.setStringList('timeEntries', timeEntriesJson);
  }
  
  Future<void> _saveData() async {
    await _saveActivities();
    await _saveTimeEntries();
  }
  
  Future<void> _checkForActiveTimeEntries() async {
    // Check if there's an active time entry from the background service
    final activeDetails = await BackgroundService.getActiveActivityDetails();
    
    if (activeDetails == null) {
      debugPrint('No active activity found in background service');
      _currentActivityId = null;
      return;
    }
    
    final activityId = activeDetails['id'] as String;
    debugPrint('Found active activity in background service: $activityId');
    
    // Check if we already have an active time entry for this activity
    final activeEntries = _timeEntries.where(
      (entry) => entry.activityId == activityId && entry.endTime == null
    ).toList();
    
    if (activeEntries.isEmpty) {
      debugPrint('Creating new time entry for active activity: $activityId');
      // Create a new time entry for the active activity
      final startTime = DateTime.now().subtract(activeDetails['elapsed'] as Duration);
      
      final newTimeEntry = TimeEntry(
        id: const Uuid().v4(),
        activityId: activityId,
        startTime: startTime,
        endTime: null,
      );
      
      _timeEntries.add(newTimeEntry);
      _currentActivityId = activityId;
      notifyListeners();
      return;
    }
    
    // If there's an active entry, set it as the current activity
    debugPrint('Found existing time entry for active activity: $activityId');
    _currentActivityId = activeEntries.first.activityId;
    notifyListeners();
  }
  
  Future<void> startActivity(String activityId) async {
    debugPrint('Starting activity: $activityId');
    
    // If there's already an active activity, stop it first
    if (_currentActivityId != null) {
      await stopCurrentActivity();
    }
    
    // Find the activity
    final activity = activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => Activity(
        id: activityId,
        name: 'Unknown Activity',
        color: '0xFF4CAF50',
        icon: 'work',
      ),
    );
    
    // Create a new time entry
    final timeEntry = TimeEntry(
      id: const Uuid().v4(),
      activityId: activityId,
      startTime: DateTime.now(),
      endTime: null,
    );
    
    // Add the time entry to the list
    _timeEntries.add(timeEntry);
    
    // Set the current activity
    _currentActivityId = activityId;
    
    // Start the background service timer
    await BackgroundService.startTimer(activityId, activity.name, activity.icon);
    
    // Save the data
    await _saveData();
    
    // Notify listeners
    notifyListeners();
  }

  Future<void> stopCurrentActivity() async {
    if (_currentActivityId == null) {
      debugPrint('No active activity to stop');
      return;
    }
    
    debugPrint('Stopping current activity: $_currentActivityId');
    
    // Find the active time entry
    final activeTimeEntry = _timeEntries.firstWhere(
      (entry) => entry.activityId == _currentActivityId && entry.endTime == null,
      orElse: () => TimeEntry(
        id: const Uuid().v4(),
        activityId: _currentActivityId!,
        startTime: DateTime.now().subtract(const Duration(minutes: 1)),
        endTime: null,
      ),
    );
    
    // Update the end time
    final updatedEntry = TimeEntry(
      id: activeTimeEntry.id,
      activityId: activeTimeEntry.activityId,
      startTime: activeTimeEntry.startTime,
      endTime: DateTime.now(),
    );
    
    // Replace the entry in the list
    final index = _timeEntries.indexWhere((entry) => entry.id == activeTimeEntry.id);
    if (index >= 0) {
      _timeEntries[index] = updatedEntry;
    } else {
      _timeEntries.add(updatedEntry);
    }
    
    // Clear the current activity
    _currentActivityId = null;
    
    // Stop the background service timer
    await BackgroundService.stopTimer();
    
    // Save the data
    await _saveData();
    
    // Notify listeners
    notifyListeners();
  }
  
  Future<void> addActivity(String name, String color, String icon) async {
    final newActivity = Activity(
      id: const Uuid().v4(),
      name: name,
      color: color,
      icon: icon,
    );
    
    _activities.add(newActivity);
    await _saveActivities();
    notifyListeners();
  }
  
  Future<void> updateActivity(String activityId, String name, String color, String icon) async {
    final index = _activities.indexWhere((a) => a.id == activityId);
    if (index != -1) {
      // Create a new activity with updated values but preserve isDefault status
      final isDefault = _activities[index].isDefault;
      _activities[index] = Activity(
        id: activityId,
        name: name,
        color: color,
        icon: icon,
        isDefault: isDefault,
      );
      
      await _saveActivities();
      notifyListeners();
    }
  }
  
  Future<void> updateActivityObject(Activity activity) async {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    
    if (index != -1) {
      _activities[index] = activity;
      await _saveActivities();
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> deleteActivity(String activityId) async {
    // Don't allow deleting an activity if it's currently active
    if (currentActivityId == activityId) {
      return {
        'success': false,
        'message': 'Cannot delete an activity that is currently being tracked. Please stop tracking first.'
      };
    }
    
    // Check if this is a default activity
    final activity = _activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => Activity(
        id: '',
        name: '',
        color: '',
        icon: '',
      ),
    );
    
    if (activity.isDefault) {
      return {
        'success': false,
        'message': 'Default activities cannot be deleted.'
      };
    }
    
    // Remove the activity
    _activities.removeWhere((a) => a.id == activityId);
    
    // Also remove all time entries associated with this activity
    _timeEntries.removeWhere((entry) => entry.activityId == activityId);
    
    await _saveActivities();
    await _saveTimeEntries();
    notifyListeners();
    
    return {
      'success': true,
      'message': 'Activity deleted successfully'
    };
  }
  
  List<TimeEntry> getTimeEntriesForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _timeEntries
        .where((entry) => 
            entry.startTime.isAfter(startOfDay) && 
            (entry.endTime?.isBefore(endOfDay) ?? false))
        .toList();
  }
  
  List<TimeEntry> getTimeEntriesForDateRange(DateTime start, DateTime end) {
    final startOfRange = DateTime(start.year, start.month, start.day);
    final endOfRange = DateTime(end.year, end.month, end.day, 23, 59, 59);
    
    return _timeEntries
        .where((entry) => 
            entry.startTime.isAfter(startOfRange) && 
            (entry.endTime?.isBefore(endOfRange) ?? false))
        .toList();
  }
  
  Map<String, Duration> getActivityDurationsForDay(DateTime date) {
    final entries = getTimeEntriesForDay(date);
    return _calculateDurationsByActivity(entries);
  }
  
  Map<String, Duration> getActivityDurationsForDateRange(DateTime start, DateTime end) {
    final entries = getTimeEntriesForDateRange(start, end);
    return _calculateDurationsByActivity(entries);
  }
  
  Map<String, Duration> _calculateDurationsByActivity(List<TimeEntry> entries) {
    final result = <String, Duration>{};
    
    for (final entry in entries) {
      if (entry.endTime != null) {
        final activityId = entry.activityId;
        final duration = entry.duration;
        
        if (result.containsKey(activityId)) {
          result[activityId] = result[activityId]! + duration;
        } else {
          result[activityId] = duration;
        }
      }
    }
    
    return result;
  }
  
  Activity? getActivityById(String id) {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Clear all time entries but keep activities
  Future<void> clearAllTimeEntries() async {
    // Stop any active tracking
    if (isTracking) {
      await stopCurrentActivity();
    }
    
    // Clear only time entries, keep activities
    _timeEntries = [];
    
    // Save empty time entries list to SharedPreferences
    await _saveTimeEntries();
    
    // Notify listeners that data has changed
    notifyListeners();
  }
}
