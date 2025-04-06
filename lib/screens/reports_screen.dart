import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/time_tracking_service.dart';
import '../models/activity.dart';
import '../models/time_entry.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    
    // Set system UI overlay style for better integration with the app design
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double statusBarHeight = mediaQuery.padding.top;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Activity Reports',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _periods.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          period,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Tab selection
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(
                  icon: Icon(Icons.pie_chart_rounded, size: 18),
                  text: 'Summary',
                ),
                Tab(
                  icon: Icon(Icons.timeline_rounded, size: 18),
                  text: 'Daily Timeline',
                ),
              ],
            ),
          ),
          // Reports content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryView(context),
                _buildDailyTimelineView(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView(BuildContext context) {
    return Consumer<TimeTrackingService>(
      builder: (context, timeTrackingService, child) {
        // Get date range based on selected period
        final DateTimeRange dateRange = _getDateRange(_selectedPeriod);
        
        // Get time entries for the selected period
        final List<TimeEntry> timeEntries = timeTrackingService.getTimeEntriesForDateRange(
          dateRange.start,
          dateRange.end,
        );
        
        // Calculate total duration
        final Duration totalDuration = timeEntries.fold(
          Duration.zero,
          (previousValue, entry) => previousValue + (entry.endTime != null
              ? entry.endTime!.difference(entry.startTime)
              : const Duration()),
        );
        
        // Get activity durations
        final Map<String, Duration> activityDurations = timeTrackingService.getActivityDurationsForDateRange(
          dateRange.start,
          dateRange.end,
        );
        
        // Sort activities by duration (descending)
        final List<MapEntry<String, Duration>> sortedActivities = activityDurations.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // Calculate percentages for pie chart
        final List<PieChartSectionData> pieChartSections = [];
        final List<Widget> legendItems = [];
        
        if (sortedActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available for this period',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Start tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          );
        }
        
        double totalSeconds = totalDuration.inSeconds.toDouble();
        if (totalSeconds == 0) totalSeconds = 1; // Avoid division by zero
        
        for (int i = 0; i < sortedActivities.length; i++) {
          final activity = timeTrackingService.getActivityById(sortedActivities[i].key);
          if (activity == null) continue;
          
          final duration = sortedActivities[i].value;
          final percentage = duration.inSeconds / totalSeconds;
          final color = Color(int.parse(activity.color));
          
          pieChartSections.add(
            PieChartSectionData(
              color: color,
              value: percentage * 100,
              title: '${(percentage * 100).toStringAsFixed(1)}%',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              badgeWidget: percentage < 0.05 ? null : Icon(
                _getIconData(activity.icon),
                size: 16,
                color: Colors.white,
              ),
              badgePositionPercentageOffset: 0.8,
            ),
          );
          
          legendItems.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date range and total time
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primaryContainer.withBlue(
                          (Theme.of(context).colorScheme.primaryContainer.blue + 15).clamp(0, 255)
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time Period',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPeriod,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(totalDuration),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(dateRange.start),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(dateRange.end),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Pie chart
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pie chart
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: PieChart(
                            PieChartData(
                              sections: pieChartSections,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                              centerSpaceColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Legend
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 12),
                          child: Text(
                            'Activities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ),
                        Container(
                          height: 120,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: legendItems,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDailyTimelineView(BuildContext context) {
    return Consumer<TimeTrackingService>(
      builder: (context, timeTrackingService, child) {
        // Get date for today
        final DateTime selectedDate = _selectedPeriod == 'Today' 
            ? DateTime.now() 
            : DateTime.now().subtract(const Duration(days: 1));
        
        // Get time entries for the selected day
        final List<TimeEntry> timeEntries = timeTrackingService.getTimeEntriesForDay(selectedDate);
        
        if (timeEntries.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timeline_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activities tracked today',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking activities to see your daily timeline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Sort time entries by start time
        timeEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Timeline visualization
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.timeline_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '24-Hour Timeline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 24-hour timeline
                      Expanded(
                        child: _build24HourTimeline(context, timeEntries, timeTrackingService),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _build24HourTimeline(BuildContext context, List<TimeEntry> timeEntries, TimeTrackingService timeTrackingService) {
    // Create a list of all hours in a day
    final List<int> hours = List.generate(24, (index) => index);
    
    return ListView.builder(
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        final hourStart = DateTime(
          timeEntries.first.startTime.year,
          timeEntries.first.startTime.month,
          timeEntries.first.startTime.day,
          hour,
        );
        final hourEnd = hourStart.add(const Duration(hours: 1));
        
        // Filter time entries that overlap with this hour
        final List<TimeEntry> entriesInHour = timeEntries.where((entry) {
          final entryEnd = entry.endTime ?? DateTime.now();
          return (entry.startTime.isBefore(hourEnd) && entryEnd.isAfter(hourStart));
        }).toList();
        
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hour indicator
                SizedBox(
                  width: 50,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                
                // Timeline line
                Container(
                  width: 2,
                  height: entriesInHour.isEmpty ? 30 : null,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                
                // Activities in this hour
                if (entriesInHour.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entriesInHour.map((entry) {
                        // Find activity details
                        final activity = timeTrackingService.activities.firstWhere(
                          (a) => a.id == entry.activityId,
                          orElse: () => Activity(
                            id: '',
                            name: 'Unknown',
                            color: '0xFF9E9E9E',
                            icon: 'access_time',
                          ),
                        );
                        
                        // Calculate duration within this hour
                        final entryStart = entry.startTime.isAfter(hourStart) ? entry.startTime : hourStart;
                        final entryEnd = (entry.endTime ?? DateTime.now()).isBefore(hourEnd) 
                            ? (entry.endTime ?? DateTime.now()) 
                            : hourEnd;
                        final durationInHour = entryEnd.difference(entryStart);
                        
                        // Calculate percentage of hour
                        final percentOfHour = durationInHour.inMinutes / 60;
                        final double maxWidth = MediaQuery.of(context).size.width - 100; // Adjust for padding and timeline
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time range
                              Text(
                                '${DateFormat('HH:mm').format(entryStart)} - ${DateFormat('HH:mm').format(entryEnd)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Activity bar
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final double availableWidth = constraints.maxWidth;
                                  final double barWidth = availableWidth * percentOfHour;
                                  
                                  return Container(
                                    height: 30,
                                    width: barWidth > 0 ? barWidth : 30, // Minimum width for very short activities
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(activity.color)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    alignment: Alignment.centerLeft,
                                    child: barWidth < 50 
                                      ? Icon(
                                          _getIconData(activity.icon),
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getIconData(activity.icon),
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                activity.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
            
            // Divider between hours
            if (index < hours.length - 1)
              const Divider(height: 16, thickness: 0.5),
          ],
        );
      },
    );
  }
  
  DateTimeRange _getDateRange(String period) {
    final now = DateTime.now();
    
    switch (period) {
      case 'Today':
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      
      case 'This Week':
        // Start from the previous Sunday (or whatever is considered the first day of the week)
        final start = now.subtract(Duration(days: now.weekday % 7));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: now,
        );
      
      case 'This Month':
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      
      case 'This Year':
        final start = DateTime(now.year, 1, 1);
        return DateTimeRange(start: start, end: now);
      
      default:
        // Default to today
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
    }
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    return '$hours h $minutes min';
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
}
