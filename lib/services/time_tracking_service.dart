import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../models/time_entry.dart';
import 'background_service.dart';
import 'notification_service.dart';

class TimeTrackingService extends ChangeNotifier {
  late SharedPreferences _prefs;

  List<Activity> _activities = [];
  List<TimeEntry> _timeEntries = [];

  String? _currentActivityId;
  //final NotificationService _notificationService = NotificationService();

  List<Activity> get activities => _activities;
  List<TimeEntry> get timeEntries => _timeEntries;
  String? get currentActivityId => _currentActivityId;

  bool get isTracking => _currentActivityId != null;

  // Track the last time we calculated duration to prevent too frequent updates
  DateTime _lastDurationCalculation = DateTime.now();
  Duration _cachedCurrentDuration = Duration.zero;

  // Fields for caching duration calculations
  DateTime _lastDurationByDayCalculationTime = DateTime(2000);
  DateTime? _lastDurationByDayDate;
  Map<String, Duration>? _cachedDurationsByDay;

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
    final activitiesJson =
        _activities.map((activity) => jsonEncode(activity.toJson())).toList();

    await _prefs.setStringList('activities', activitiesJson);
  }

  Future<void> _saveTimeEntries() async {
    final timeEntriesJson =
        _timeEntries.map((entry) => jsonEncode(entry.toJson())).toList();

    await _prefs.setStringList('timeEntries', timeEntriesJson);
  }

  Future<void> _saveData() async {
    await _saveActivities();
    await _saveTimeEntries();
  }

  Future<void> _checkForActiveTimeEntries() async {
    // Check if there's an active time entry from the background service
    final activeDetails = await BackgroundService().getActiveActivityDetails();

    if (activeDetails == null) {
      debugPrint('No active activity found in background service');
      _currentActivityId = null;
      return;
    }

    final activityId = activeDetails['id'] as String;
    debugPrint('Found active activity in background service: $activityId');

    // Check if we already have an active time entry for this activity
    final activeEntries = _timeEntries
        .where(
            (entry) => entry.activityId == activityId && entry.endTime == null)
        .toList();

    if (activeEntries.isEmpty) {
      debugPrint('Creating new time entry for active activity: $activityId');
      // Create a new time entry for the active activity
      final startTime =
          DateTime.now().subtract(activeDetails['elapsed'] as Duration);

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
    await BackgroundService()
        .startTimer(activityId, activity.name, activity.icon);

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
      (entry) =>
          entry.activityId == _currentActivityId && entry.endTime == null,
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
    final index =
        _timeEntries.indexWhere((entry) => entry.id == activeTimeEntry.id);
    if (index >= 0) {
      _timeEntries[index] = updatedEntry;
    } else {
      _timeEntries.add(updatedEntry);
    }

    // Clear the current activity
    _currentActivityId = null;

    // Stop the background service timer
    await BackgroundService().stopTimer();

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

  Future<void> updateActivity(
      String activityId, String name, String color, String icon) async {
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
        'message':
            'Cannot delete an activity that is currently being tracked. Please stop tracking first.'
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

    return {'success': true, 'message': 'Activity deleted successfully'};
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
    final now = DateTime.now();

    // Check if we have a recent cache for this date
    final dateKey = DateTime(date.year, date.month, date.day);
    final sameDate = _lastDurationByDayDate != null &&
        _lastDurationByDayDate!.year == dateKey.year &&
        _lastDurationByDayDate!.month == dateKey.month &&
        _lastDurationByDayDate!.day == dateKey.day;

    // If we have a recent calculation for the same date (within the last second), return cached result
    if (sameDate && _cachedDurationsByDay != null &&
        now.difference(_lastDurationByDayCalculationTime).inSeconds < 1) {
      debugPrint('### RETURNING CACHED DURATIONS FOR DAY ###');
      return Map<String, Duration>.from(_cachedDurationsByDay!);
    }

    // Otherwise, perform the calculation
    debugPrint('### DURATION CALCULATION STARTED ###');
    _lastDurationByDayDate = dateKey;
    _lastDurationByDayCalculationTime = now;

    final entries = getTimeEntriesForDay(date);
    debugPrint('Number of time entries for ${date.toString().split(' ')[0]}: ${entries.length}');

    // Calculate durations from completed time entries only
    final Map<String, Duration> result = {};
    for (final entry in entries) {
      if (entry.endTime != null) { // Only include completed entries
        final duration = entry.endTime!.difference(entry.startTime);
        if (result.containsKey(entry.activityId)) {
          result[entry.activityId] = result[entry.activityId]! + duration;
        } else {
          result[entry.activityId] = duration;
        }
        debugPrint('Added completed entry duration: ${duration.inSeconds}s for activity ${entry.activityId}');
      }
    }

    debugPrint('Completed entries durations: $result');

    // If there's an active activity, add its current duration to the total
    if (isTracking && _currentActivityId != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);

      // Only include if the activity was started today
      if (now.year == date.year && now.month == date.month && now.day == date.day) {
        // Find the active time entry
        final activeEntry = _timeEntries.firstWhere(
          (entry) => entry.activityId == _currentActivityId && entry.endTime == null,
          orElse: () => TimeEntry(
            id: '',
            activityId: _currentActivityId!,
            startTime: now,
            endTime: null,
          ),
        );

        debugPrint('Active time entry found: ${activeEntry.activityId}, started at: ${activeEntry.startTime}');

        // Calculate the current duration, but throttle updates to once per second
        Duration currentDuration;

        // Get the caller's stack trace
        StackTrace stackTrace = StackTrace.current;
        debugPrint('STACK TRACE: $stackTrace');

        // Only recalculate if it's been at least 1 second since the last calculation
        if (now.difference(_lastDurationCalculation).inSeconds >= 1) {
          _lastDurationCalculation = now;
          _cachedCurrentDuration = now.difference(activeEntry.startTime);
          debugPrint('Recalculated duration at ${now.toString()}: ${_cachedCurrentDuration.inSeconds}s');
        }

        // Use the cached duration value
        currentDuration = _cachedCurrentDuration;
        debugPrint('Using cached duration: ${currentDuration.inSeconds}s');

        // Debug before adding
        debugPrint('Before adding current: ${result[activeEntry.activityId]?.inSeconds ?? 0}s');

        // Add to the result
        final activityId = activeEntry.activityId;
        if (result.containsKey(activityId)) {
          result[activityId] = result[activityId]! + currentDuration;
        } else {
          result[activityId] = currentDuration;
        }

        // Debug after adding
        debugPrint('After adding current: ${result[activityId]?.inSeconds}s');
        debugPrint('Added current duration of ${currentDuration.inSeconds}s to activity $activityId');
      }
    }

    // Debug final result
    for (final entry in result.entries) {
      final activity = getActivityById(entry.key);
      final activityName = activity?.name ?? 'Unknown';
      debugPrint('Activity $activityName - Total duration: ${entry.value.inSeconds}s (current: ${isTracking && _currentActivityId == entry.key ? _cachedCurrentDuration.inSeconds : 0}s)');
    }

    // Cache the result for future calls
    _cachedDurationsByDay = Map<String, Duration>.from(result);

    debugPrint('### DURATION CALCULATION COMPLETED ###');
    return result;
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
        final duration = entry.endTime!.difference(entry.startTime);

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

  // Get the currently active time entry, if any
  TimeEntry? getActiveTimeEntry() {
    if (!isTracking || _currentActivityId == null) {
      return null;
    }

    try {
      return _timeEntries.firstWhere(
        (entry) => entry.activityId == _currentActivityId && entry.endTime == null,
      );
    } catch (e) {
      debugPrint('No active time entry found: $e');
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
