import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../models/time_entry.dart';
import 'background_service.dart';
import 'notification_service.dart';
import 'database_helper.dart';

class TimeTrackingService extends ChangeNotifier {
  // Keys for SharedPreferences (only used for current activity state)
  static const String _currentActivityIdKey = 'current_activity_id';
  static const String _isTrackingKey = 'is_tracking';

  // Database helper
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // SharedPreferences for tracking state only
  late SharedPreferences _prefs;
  
  // In-memory cache of data
  List<Activity> _activities = [];
  List<TimeEntry> _timeEntries = [];
  String? _currentActivityId;
  bool _isTracking = false;

  // Fields for caching duration calculations
  DateTime _lastDurationCalculation = DateTime.now();
  Duration _cachedCurrentDuration = Duration.zero;
  
  // Fields for caching getActivityDurationsForDay
  DateTime _lastDurationByDayCalculationTime = DateTime(2000);
  DateTime? _lastDurationByDayDate;
  Map<String, Duration>? _cachedDurationsByDay;
  
  // Centralized update stream
  final StreamController<void> _activityUpdateController = StreamController.broadcast();
  Stream<void> get activityUpdateStream => _activityUpdateController.stream;
  Timer? _updateTimer;
  
  // Update frequency in seconds (adjust as needed for battery optimization)
  static const int _updateFrequencySeconds = 10; // Increased to reduce battery usage
  
  // Track app lifecycle state to manage timers properly
  bool _isInBackground = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Initialize background service
    await BackgroundService.initializeService();

    // Load activities from database
    _activities = await _dbHelper.getActivities(includeArchived: true);

    // Load time entries from database
    _timeEntries = await _dbHelper.getAllTimeEntries();

    // Load current activity state from SharedPreferences (still using SharedPreferences for this)
    _currentActivityId = _prefs.getString(_currentActivityIdKey);
    _isTracking = _prefs.getBool(_isTrackingKey) ?? false;
    
    // Create default activities if none exist
    if (_activities.isEmpty) {
      await _createDefaultActivities();
    }

    // Check for any active time entries from background service
    await _checkForActiveTimeEntries();
    
    // Start the centralized update timer if tracking is active
    _setupUpdateTimer();

    notifyListeners();
  }
  
  void _setupUpdateTimer() {
    // Cancel any existing timer
    _updateTimer?.cancel();
    
    // Only start the timer if we're tracking an activity
    if (_isTracking && _currentActivityId != null) {
      // Use different update frequencies based on app state
      final updateFrequency = _isInBackground 
          ? Duration(seconds: _updateFrequencySeconds * 3) // Less frequent updates in background
          : Duration(seconds: _updateFrequencySeconds);     // Normal frequency in foreground
      
      // Create a timer that updates at the specified frequency
      _updateTimer = Timer.periodic(updateFrequency, (_) {
        try {
          // Notify all listeners that the time has updated
          if (!_activityUpdateController.isClosed) {
            _activityUpdateController.add(null);
          }
          
          // Only log in debug mode to reduce overhead
          if (kDebugMode) {
            debugPrint('TimeTrackingService: Broadcasting time update to all listeners');
          }
        } catch (e) {
          debugPrint('Error in update timer: $e');
        }
      });
      
      debugPrint('TimeTrackingService: Started update timer with frequency ${updateFrequency.inSeconds} seconds');
    }
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    
    // Make sure we close the controller only if it's not already closed
    if (!_activityUpdateController.isClosed) {
      _activityUpdateController.close();
    }
    
    // Ensure background service is properly disposed if the app is being terminated
    BackgroundService().dispose().catchError((e) {
      debugPrint('Error disposing background service: $e');
    });
    
    super.dispose();
  }
  
  // Handle app lifecycle changes to manage timers properly
  void handleAppLifecycleChange(AppLifecycleState state) {
    debugPrint('TimeTrackingService: App lifecycle changed to $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isInBackground = false;
        // Refresh data and restart UI updates when app is resumed
        refreshTimeEntries();
        _setupUpdateTimer();
        break;
        
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isInBackground = true;
        // Reduce update frequency when app is in background
        _optimizeTimerForBackground();
        break;
        
      case AppLifecycleState.detached:
        // App is being terminated, ensure all resources are released
        _updateTimer?.cancel();
        _updateTimer = null;
        break;
        
      default:
        break;
    }
  }
  
  // Optimize timer frequency based on app state
  void _optimizeTimerForBackground() {
    if (!_isTracking || _currentActivityId == null) return;
    
    // Cancel existing timer
    _updateTimer?.cancel();
    
    // If in background, use a less frequent update interval to save battery
    if (_isInBackground) {
      _updateTimer = Timer.periodic(const Duration(seconds: _updateFrequencySeconds * 3), (_) {
        // Only perform essential updates in background
        _activityUpdateController.add(null);
      });
      debugPrint('TimeTrackingService: Optimized timer for background mode');
    } else {
      // In foreground, use normal update frequency
      _setupUpdateTimer();
    }
  }

  List<Activity> get activities => _activities;
  List<TimeEntry> get timeEntries => _timeEntries;
  String? get currentActivityId => _currentActivityId;
  bool get isTracking => _isTracking;

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

    // Save to database
    await _dbHelper.insertActivities(_activities);
  }

  // Save activities to database
  Future<void> _saveActivities() async {
    // Clear and reinsert all activities
    for (final activity in _activities) {
      await _dbHelper.updateActivity(activity);
    }
  }

  // Save time entries to database
  Future<void> _saveTimeEntries() async {
    // We don't need to save all entries each time
    // The database operations handle individual entries
  }

  // This method is kept for backward compatibility but does nothing
  Future<void> _saveData() async {
    // No need to do anything as database operations are performed immediately
  }

  // Lock to prevent concurrent execution of _checkForActiveTimeEntries
  Completer<void>? _checkActiveLock;
  bool _isCheckingActiveEntries = false;

  Future<void> _checkForActiveTimeEntries() async {
    // Prevent concurrent execution
    if (_isCheckingActiveEntries) {
      debugPrint('Already checking for active entries, waiting for completion');
      if (_checkActiveLock != null) {
        await _checkActiveLock!.future;
      }
      return;
    }

    // Create a new lock for this execution
    _checkActiveLock = Completer<void>();
    _isCheckingActiveEntries = true;

    try {
      // Check if there's an active time entry from the background service
      final activeDetails = await BackgroundService().getActiveActivityDetails();

      if (activeDetails == null) {
        debugPrint('No active activity found in background service');
        _currentActivityId = null;
        _isCheckingActiveEntries = false;
        if (_checkActiveLock != null) {
          _checkActiveLock!.complete();
          _checkActiveLock = null;
        }
        return;
      }

      final activityId = activeDetails['id'] as String;
      debugPrint('Found active activity in background service: $activityId');

      // Check if we already have an active time entry for this activity
      final ongoingEntry = await _dbHelper.getOngoingTimeEntry();

      if (ongoingEntry == null) {
        debugPrint('Creating new time entry for active activity: $activityId');
        // Create a new time entry for the active activity
        final startTime = DateTime.now().subtract(activeDetails['elapsed'] as Duration);

        final newTimeEntry = TimeEntry(
          id: const Uuid().v4(),
          activityId: activityId,
          startTime: startTime,
          endTime: null,
        );

        await _dbHelper.insertTimeEntry(newTimeEntry);
        _timeEntries.add(newTimeEntry);
        _currentActivityId = activityId;
        notifyListeners();
      } else {
        // If there's an active entry, set it as the current activity
        debugPrint('Found existing time entry for active activity: ${ongoingEntry.activityId}');
        _currentActivityId = ongoingEntry.activityId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking for active time entries: $e');
    } finally {
      _isCheckingActiveEntries = false;
      if (_checkActiveLock != null) {
        _checkActiveLock!.complete();
        _checkActiveLock = null;
      }
    }
  }
  Future<void> startActivity(String activityId) async {
    debugPrint('Starting activity: $activityId');

    if (_isTracking && _currentActivityId == activityId) {
      return; // Already tracking this activity
    }

    // Stop current activity if any
    if (_isTracking) {
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

    final now = DateTime.now();
    final timeEntry = TimeEntry(
      id: const Uuid().v4(),
      activityId: activityId,
      startTime: now,
      endTime: null,
    );

    // Save to database
    await _dbHelper.insertTimeEntry(timeEntry);
    
    // Update in-memory cache
    _timeEntries.add(timeEntry);
    
    // Refresh time entries from database to ensure consistency
    await refreshTimeEntries();
    
    _currentActivityId = activityId;
    _isTracking = true;
    _lastDurationCalculation = now;
    _cachedCurrentDuration = Duration.zero;

    // Start the background service timer
    await BackgroundService().startTimer(activityId, activity.name, activity.icon);

    // Save tracking state to SharedPreferences
    await _prefs.setString(_currentActivityIdKey, activityId);
    await _prefs.setBool(_isTrackingKey, true);
    
    // Start the update timer when an activity is started
    _setupUpdateTimer();

    notifyListeners();
  }

  Future<void> stopCurrentActivity() async {
    if (!_isTracking || _currentActivityId == null) {
      debugPrint('No active activity to stop');
      return;
    }

    debugPrint('Stopping current activity: $_currentActivityId');

    final now = DateTime.now();
    
    // Find the ongoing time entry in the database
    final currentEntry = await _dbHelper.getOngoingTimeEntry();
    
    if (currentEntry == null) {
      debugPrint('No active time entry found in database');
      
      // Create a new entry as fallback
      final newEntry = TimeEntry(
        id: const Uuid().v4(),
        activityId: _currentActivityId!,
        startTime: now.subtract(const Duration(minutes: 1)),
        endTime: now,
      );
      
      await _dbHelper.insertTimeEntry(newEntry);
      
      // Update in-memory cache
      _timeEntries.add(newEntry);
    } else {
      // Update the entry with end time
      final updatedEntry = TimeEntry(
        id: currentEntry.id,
        activityId: currentEntry.activityId,
        startTime: currentEntry.startTime,
        endTime: now,
      );
      
      // Update in database
      await _dbHelper.updateTimeEntry(updatedEntry);
      
      // Update in-memory cache
      final index = _timeEntries.indexWhere((entry) => entry.id == currentEntry.id);
      if (index >= 0) {
        _timeEntries[index] = updatedEntry;
      } else {
        _timeEntries.add(updatedEntry);
      }
    }
    
    // Refresh time entries from database to ensure consistency
    await refreshTimeEntries();

    _isTracking = false;
    _currentActivityId = null;

    // Stop the background service timer
    await BackgroundService().stopTimer();

    // Update SharedPreferences
    await _prefs.remove(_currentActivityIdKey);
    await _prefs.setBool(_isTrackingKey, false);
    
    // Stop the update timer when activity is stopped
    _updateTimer?.cancel();
    _updateTimer = null;

    notifyListeners();
  }

  Future<void> addActivity(String name, String color, String icon) async {
    final newActivity = Activity(
      id: const Uuid().v4(),
      name: name,
      color: color,
      icon: icon,
    );

    // Save to database
    await _dbHelper.insertActivity(newActivity);
    
    // Update in-memory cache
    _activities.add(newActivity);
    
    notifyListeners();
  }

  Future<void> updateActivity(
      String activityId, String name, String color, String icon) async {
    final index = _activities.indexWhere((a) => a.id == activityId);
    if (index != -1) {
      // Create a new activity with updated values but preserve isDefault status
      final isDefault = _activities[index].isDefault;
      final updatedActivity = Activity(
        id: activityId,
        name: name,
        color: color,
        icon: icon,
        isDefault: isDefault,
      );
      
      // Update in database
      await _dbHelper.updateActivity(updatedActivity);
      
      // Update in-memory cache
      _activities[index] = updatedActivity;
      
      notifyListeners();
    }
  }

  Future<void> updateActivityObject(Activity activity) async {
    final index = _activities.indexWhere((a) => a.id == activity.id);

    if (index != -1) {
      // Update in database
      await _dbHelper.updateActivity(activity);
      
      // Update in-memory cache
      _activities[index] = activity;
      
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

    // Delete from database
    await _dbHelper.deleteActivity(activityId);
    
    // Update in-memory cache
    _activities.removeWhere((a) => a.id == activityId);
    _timeEntries.removeWhere((entry) => entry.activityId == activityId);

    notifyListeners();

    return {'success': true, 'message': 'Activity deleted successfully'};
  }

  List<TimeEntry> getTimeEntriesForDay(DateTime date) {
    // Use the in-memory cache but also check for any active entries
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    // Debug logging
    debugPrint('Getting time entries for day: ${date.toString().split(' ')[0]}');
    debugPrint('Total entries in memory: ${_timeEntries.length}');
    
    // Filter entries for the specified day
    final entriesForDay = _timeEntries
        .where((entry) =>
            (entry.startTime.isAfter(startOfDay) || entry.startTime.isAtSameMomentAs(startOfDay)) &&
            (entry.endTime == null || entry.endTime!.isBefore(endOfDay) || entry.endTime!.isAtSameMomentAs(endOfDay)))
        .toList();
    
    debugPrint('Found ${entriesForDay.length} entries for ${date.toString().split(' ')[0]} in memory');
    return entriesForDay;
  }

  Future<List<TimeEntry>> getTimeEntriesForDayFromDb(DateTime date) async {
    // Direct database query for better performance
    return await _dbHelper.getTimeEntriesForDay(date);
  }

  List<TimeEntry> getTimeEntriesForDateRange(DateTime start, DateTime end) {
    // This could be optimized to query directly from the database
    // but for now we'll keep the same API and use the in-memory cache
    final startOfRange = DateTime(start.year, start.month, start.day);
    final endOfRange = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return _timeEntries
        .where((entry) =>
            (entry.startTime.isAfter(startOfRange) || entry.startTime.isAtSameMomentAs(startOfRange)) &&
            (entry.endTime == null || entry.endTime!.isBefore(endOfRange) || entry.endTime!.isAtSameMomentAs(endOfRange)))
        .toList();
  }

  Future<List<TimeEntry>> getTimeEntriesForDateRangeFromDb(DateTime start, DateTime end) async {
    // Direct database query for better performance
    return await _dbHelper.getTimeEntriesForDateRange(start, end);
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

    // Clear time entries from database
    await _dbHelper.deleteAllTimeEntries();
    
    // Clear in-memory cache
    _timeEntries.clear();

    // Notify listeners that data has changed
    notifyListeners();
  }

  /// Add a test time entry with specific start and end times
  /// This method is for testing purposes only
  Future<void> addTestTimeEntry({
    required String activityId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Validate that the activity exists
    final activityExists = _activities.any((activity) => activity.id == activityId);
    if (!activityExists) {
      debugPrint('Cannot add test entry: Activity with ID $activityId does not exist');
      return;
    }
    
    // Validate that end time is after start time
    if (endTime.isBefore(startTime)) {
      debugPrint('Cannot add test entry: End time must be after start time');
      return;
    }
    
    // Create and add the time entry
    final timeEntry = TimeEntry(
      id: const Uuid().v4(),
      activityId: activityId,
      startTime: startTime,
      endTime: endTime,
    );
    
    // Save to database
    await _dbHelper.insertTimeEntry(timeEntry);
    
    // Update in-memory cache
    _timeEntries.add(timeEntry);
    
    // No need to notify listeners as this is for test data generation
  }
  
  // Refresh the in-memory cache from the database
  Future<void> refreshFromDatabase() async {
    _activities = await _dbHelper.getActivities(includeArchived: true);
    _timeEntries = await _dbHelper.getAllTimeEntries();
    notifyListeners();
  }

  // This method should be called after any database operations to ensure the in-memory cache is up to date
  Future<void> refreshTimeEntries() async {
    _timeEntries = await _dbHelper.getAllTimeEntries();
    debugPrint('Refreshed time entries from database. Total entries: ${_timeEntries.length}');
    notifyListeners();
  }

  Future<void> loadData() async {
    debugPrint('Loading data from database...');
    
    // Load activities and time entries from database
    _activities = await _dbHelper.getAllActivities();
    _timeEntries = await _dbHelper.getAllTimeEntries();
    
    debugPrint('Loaded ${_activities.length} activities and ${_timeEntries.length} time entries');
    
    // Check if there's an ongoing time entry
    final ongoingEntry = await _dbHelper.getOngoingTimeEntry();
    if (ongoingEntry != null) {
      debugPrint('Found ongoing time entry: ${ongoingEntry.id} for activity ${ongoingEntry.activityId}');
      
      _currentActivityId = ongoingEntry.activityId;
      _isTracking = true;
      _lastDurationCalculation = DateTime.now();
      _cachedCurrentDuration = _lastDurationCalculation.difference(ongoingEntry.startTime);
      
      // Start the update timer
      _setupUpdateTimer();
      
      // Update SharedPreferences to match database state
      await _prefs.setString(_currentActivityIdKey, ongoingEntry.activityId);
      await _prefs.setBool(_isTrackingKey, true);
      
      // Start the background service timer
      final activity = activities.firstWhere(
        (a) => a.id == ongoingEntry.activityId,
        orElse: () => Activity(
          id: ongoingEntry.activityId,
          name: 'Unknown Activity',
          color: '0xFF4CAF50',
          icon: 'work',
        ),
      );
      
      await BackgroundService().startTimer(
        ongoingEntry.activityId, 
        activity.name, 
        activity.icon
      );
    } else {
      debugPrint('No ongoing time entry found');
      
      // Clear tracking state
      _currentActivityId = null;
      _isTracking = false;
      _lastDurationCalculation = DateTime.now();
      _cachedCurrentDuration = Duration.zero;
      
      // Update SharedPreferences
      await _prefs.remove(_currentActivityIdKey);
      await _prefs.setBool(_isTrackingKey, false);
    }
    
    notifyListeners();
  }
}
