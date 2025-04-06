import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/time_tracking_service.dart';
import '../services/background_service.dart';
import '../widgets/activity_button.dart';
import '../widgets/timer_display.dart';
import '../widgets/active_activity_banner.dart';
import '../models/activity.dart';
import '../models/time_entry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Duration _elapsed = Duration.zero;
  bool _showLongPressHint = true;
  OverlayEntry? _overlayEntry;
  StreamSubscription<Duration>? _elapsedSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupElapsedTimeListener();
    _checkForActiveActivity();

    // Set system UI overlay style for better integration with the app design
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    // Show the long-press hint after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLongPressHint();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // When app is resumed, refresh the timer state
      _checkForActiveActivity();
      _setupElapsedTimeListener();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedSubscription?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _setupElapsedTimeListener() {
    // Cancel any existing subscription to avoid duplicates
    _elapsedSubscription?.cancel();

    _elapsedSubscription = BackgroundService().elapsedStream.listen((duration) {
      if (mounted) {
        setState(() {
          _elapsed = duration;
        });
        debugPrint(
            'HomeScreen received elapsed time update: ${_elapsed.inSeconds} seconds');
      }
    });
    
    // Immediately check for active activity to get the current elapsed time
    _checkForActiveActivity();
    
    // Also set up a periodic timer to update the elapsed time every second
    // This ensures the timer updates even if the stream doesn't emit frequently enough
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      _checkForActiveActivity();
    });
  }

  Future<void> _checkForActiveActivity() async {
    final activeDetails = await BackgroundService().getActiveActivityDetails();
    if (activeDetails != null) {
      if (mounted) {
        setState(() {
          _elapsed = activeDetails['elapsed'] as Duration;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _elapsed = Duration.zero;
        });
      }
    }
  }

  void _showActivitySelectionDialog(
      BuildContext context, TimeTrackingService timeTrackingService) {
    final activities = timeTrackingService.activities;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(activity.color)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconData(activity.icon),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        activity.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        timeTrackingService.startActivity(activity.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'coffee':
        return Icons.coffee;
      case 'meeting':
        return Icons.people;
      case 'study':
        return Icons.book;
      case 'gym':
        return Icons.fitness_center;
      case 'food':
        return Icons.restaurant;
      case 'sleep':
        return Icons.bedtime;
      case 'travel':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_cart;
      case 'coding':
        return Icons.code;
      case 'music':
        return Icons.music_note;
      case 'movie':
        return Icons.movie;
      case 'reading':
        return Icons.menu_book;
      case 'gaming':
        return Icons.sports_esports;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'cooking':
        return Icons.restaurant;
      default:
        return Icons.access_time;
    }
  }

  void _showHintOverlay() {
    // Remove any existing overlay
    _removeOverlay();

    // Create a new overlay
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Material(
            color: Colors.black.withOpacity(0.5),
            child: Stack(
              children: [
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            size: 32,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tip: Long press an activity to edit or delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap anywhere to dismiss',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Insert the overlay
    Overlay.of(context).insert(_overlayEntry!);

    // Add a tap handler to remove the overlay when tapped
    GestureDetector(
      onTap: _removeOverlay,
      behavior: HitTestBehavior.opaque,
      child: Container(),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  String _formatDuration(Duration duration) {
    return BackgroundService().formatDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double statusBarHeight = mediaQuery.padding.top;
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      // Don't extend body behind app bar to avoid status bar issues
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + statusBarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TrackMyWork',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Add Activity',
                        onPressed: () {
                          Navigator.pushNamed(context, '/add_activity');
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.bar_chart_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'View Reports',
                        onPressed: () {
                          Navigator.pushNamed(context, '/reports');
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<TimeTrackingService>(
        builder: (context, timeTrackingService, child) {
          final activities = timeTrackingService.activities;
          final isTracking = timeTrackingService.isTracking;
          final currentActivityId = timeTrackingService.currentActivityId;

          return Column(
            children: [
              // Timer display
              if (isTracking)
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withBlue((Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .blue +
                                        15)
                                    .clamp(0, 255)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIconData(activities
                                    .firstWhere(
                                      (a) => a.id == currentActivityId,
                                      orElse: () => Activity(
                                        id: '',
                                        name: 'Unknown Activity',
                                        color: '0xFF4CAF50',
                                        icon: 'work',
                                      ),
                                    )
                                    .icon),
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Currently tracking: ${activities.firstWhere(
                                        (a) => a.id == currentActivityId,
                                        orElse: () => Activity(
                                          id: '',
                                          name: 'Unknown Activity',
                                          color: '0xFF4CAF50',
                                          icon: 'work',
                                        ),
                                      ).name}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TimerDisplay(
                            elapsed: _elapsed,
                            activityName: activities
                                .firstWhere(
                                  (a) => a.id == currentActivityId,
                                  orElse: () => Activity(
                                    id: '',
                                    name: 'Unknown Activity',
                                    color: '0xFF4CAF50',
                                    icon: 'work',
                                  ),
                                )
                                .name,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Status message
              if (!isTracking)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.hourglass_empty_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ready to track your time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap an activity below or the start button',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Activities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${activities.length} items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Long press an activity to edit or delete',
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Activity buttons
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth > 600 ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ActivityButton(
                        activity: activity,
                        onPressed: () {
                          if (timeTrackingService.currentActivityId ==
                              activity.id) {
                            timeTrackingService.stopCurrentActivity();
                          } else {
                            timeTrackingService.startActivity(activity.id);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<TimeTrackingService>(
        builder: (context, timeTrackingService, child) {
          final isTracking = timeTrackingService.isTracking;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (isTracking
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.secondaryContainer)
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                if (isTracking) {
                  timeTrackingService.stopCurrentActivity();
                } else {
                  // Show activity selection dialog if not tracking
                  _showActivitySelectionDialog(context, timeTrackingService);
                }
              },
              label: Text(
                isTracking ? 'Stop' : 'Start Tracking',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isTracking
                      ? Theme.of(context).colorScheme.onError.withOpacity(0.2)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
              ),
              backgroundColor: isTracking
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: isTracking
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onSecondaryContainer,
              elevation: 0,
              extendedPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _maybeShowLongPressHint() async {
    // Check if we should show the hint (could be stored in preferences)
    if (_showLongPressHint) {
      // Wait for the UI to be fully built
      await Future.delayed(const Duration(seconds: 2));
      _showHintOverlay();

      // Auto-dismiss after some time
      Future.delayed(const Duration(seconds: 3), () {
        _removeOverlay();
      });
    }
  }
}
