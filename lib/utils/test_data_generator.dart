import 'dart:math';
import 'package:flutter/material.dart';
import '../services/time_tracking_service.dart';
import '../models/activity.dart';

/// Utility class to generate test data for the time tracking app
class TestDataGenerator {
  final TimeTrackingService _timeTrackingService;
  final Random _random = Random();

  TestDataGenerator(this._timeTrackingService);

  /// Generate test data for the past days
  /// [days] - Number of days to generate data for
  /// [entriesPerDay] - Average number of entries per day
  Future<void> generateDailyTestData({
    required int days,
    int entriesPerDay = 5,
  }) async {
    // First, stop any current activity
    await _timeTrackingService.stopCurrentActivity();
    
    // Get existing activities or create default ones if needed
    final activities = _timeTrackingService.activities;
    if (activities.isEmpty) {
      debugPrint('No activities found. Please create some activities first.');
      return;
    }
    
    // Generate data for each day
    for (int day = days; day > 0; day--) {
      final date = DateTime.now().subtract(Duration(days: day));
      await _generateEntriesForDay(date, activities, entriesPerDay);
      debugPrint('Generated test data for ${date.toString().split(' ')[0]}');
    }
    
    debugPrint('Test data generation completed for $days days');
  }
  
  /// Generate test data for the past months
  /// [months] - Number of months to generate data for
  /// [daysPerMonth] - Number of days per month to generate data for
  Future<void> generateMonthlyTestData({
    required int months,
    int daysPerMonth = 20,
    int entriesPerDay = 5,
  }) async {
    // First, stop any current activity
    await _timeTrackingService.stopCurrentActivity();
    
    // Get existing activities
    final activities = _timeTrackingService.activities;
    if (activities.isEmpty) {
      debugPrint('No activities found. Please create some activities first.');
      return;
    }
    
    // Generate data for each month
    for (int month = months; month > 0; month--) {
      final currentDate = DateTime.now();
      final startOfMonth = DateTime(
        currentDate.year, 
        currentDate.month - month, 
        1
      );
      
      // Generate data for random days in the month
      for (int day = 0; day < daysPerMonth; day++) {
        // Pick a random day in the month
        final daysInMonth = DateTime(
          startOfMonth.year, 
          startOfMonth.month + 1, 
          0
        ).day;
        
        final randomDay = _random.nextInt(daysInMonth) + 1;
        final date = DateTime(startOfMonth.year, startOfMonth.month, randomDay);
        
        // Don't generate future data
        if (date.isBefore(DateTime.now())) {
          await _generateEntriesForDay(date, activities, entriesPerDay);
          debugPrint('Generated test data for ${date.toString().split(' ')[0]}');
        }
      }
      
      debugPrint('Completed test data for month ${startOfMonth.month}/${startOfMonth.year}');
    }
    
    debugPrint('Test data generation completed for $months months');
  }
  
  /// Generate test data for the past years
  /// [years] - Number of years to generate data for
  /// [monthsPerYear] - Number of months per year to generate data for
  Future<void> generateYearlyTestData({
    required int years,
    int monthsPerYear = 12,
    int daysPerMonth = 15,
    int entriesPerDay = 5,
  }) async {
    // First, stop any current activity
    await _timeTrackingService.stopCurrentActivity();
    
    // Get existing activities
    final activities = _timeTrackingService.activities;
    if (activities.isEmpty) {
      debugPrint('No activities found. Please create some activities first.');
      return;
    }
    
    // Generate data for each year
    for (int year = years; year > 0; year--) {
      final currentDate = DateTime.now();
      final targetYear = currentDate.year - year;
      
      // Generate data for random months in the year
      for (int month = 1; month <= monthsPerYear; month++) {
        // Generate data for random days in the month
        for (int day = 0; day < daysPerMonth; day++) {
          // Pick a random day in the month
          final daysInMonth = DateTime(targetYear, month + 1, 0).day;
          final randomDay = _random.nextInt(daysInMonth) + 1;
          final date = DateTime(targetYear, month, randomDay);
          
          // Don't generate future data
          if (date.isBefore(DateTime.now())) {
            await _generateEntriesForDay(date, activities, entriesPerDay);
          }
        }
        
        debugPrint('Completed test data for month $month/$targetYear');
      }
      
      debugPrint('Completed test data for year $targetYear');
    }
    
    debugPrint('Test data generation completed for $years years');
  }
  
  /// Helper method to generate entries for a specific day
  Future<void> _generateEntriesForDay(
    DateTime date, 
    List<Activity> activities, 
    int entriesPerDay
  ) async {
    // Randomize the actual number of entries for this day
    final actualEntries = _random.nextInt(entriesPerDay) + 1;
    
    // Working hours are typically between 9 AM and 6 PM
    final startOfWorkDay = DateTime(date.year, date.month, date.day, 9, 0);
    
    // For each entry
    DateTime lastEndTime = startOfWorkDay;
    for (int i = 0; i < actualEntries; i++) {
      // Pick a random activity
      final activity = activities[_random.nextInt(activities.length)];
      
      // Generate a random duration between 30 minutes and 3 hours
      final durationMinutes = _random.nextInt(150) + 30;
      
      // Calculate start and end times
      final startTime = lastEndTime;
      final endTime = startTime.add(Duration(minutes: durationMinutes));
      
      // Add a small gap between activities (0-30 minutes)
      final gapMinutes = _random.nextInt(30);
      lastEndTime = endTime.add(Duration(minutes: gapMinutes));
      
      // Don't go past 6 PM
      if (endTime.hour >= 18) {
        break;
      }
      
      // Add the time entry directly to the service
      await _timeTrackingService.addTestTimeEntry(
        activityId: activity.id,
        startTime: startTime,
        endTime: endTime,
      );
    }
  }
}
