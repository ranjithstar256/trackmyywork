import 'package:flutter/material.dart';
import '../services/time_tracking_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ActivityButton extends StatelessWidget {
  final Activity activity;
  final VoidCallback onPressed;

  const ActivityButton({
    super.key,
    required this.activity,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get the time tracking service to calculate total time spent today
    final timeTrackingService = Provider.of<TimeTrackingService>(context);
    final todayDurations = timeTrackingService.getActivityDurationsForDay(DateTime.now());
    Duration activityDuration = todayDurations[activity.id] ?? Duration.zero;
    
    // Check if this activity is currently active
    final bool isActive = timeTrackingService.isTracking && 
                         timeTrackingService.currentActivityId == activity.id;
    
    // Calculate elapsed time if this is the active activity
    String elapsedTimeText = '';
    if (isActive && timeTrackingService.currentActivityId != null) {
      // We'll get the elapsed time from the background service
      elapsedTimeText = 'Active';
    }
    
    // Format the duration as HH:MM
    final hours = activityDuration.inHours;
    final minutes = activityDuration.inMinutes.remainder(60);
    final durationText = hours > 0 
        ? '$hours h ${minutes.toString().padLeft(2, '0')} m' 
        : '${minutes.toString().padLeft(2, '0')} min';
    
    return GestureDetector(
      onLongPress: () {
        if (!activity.isDefault) {
          _showActivityOptions(context);
        }
      },
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive 
              ? Color(int.parse(activity.color)).withOpacity(0.8)
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isActive 
              ? Theme.of(context).colorScheme.onPrimary
              : Color(int.parse(activity.color)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Color(int.parse(activity.color)),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: isActive ? 8 : 2,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconData(activity.icon),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                activity.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (isActive)
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (activityDuration.inSeconds > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.2)
                                : Color(int.parse(activity.color)).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Today: $durationText',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isActive 
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Color(int.parse(activity.color)),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else if (activityDuration.inSeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(int.parse(activity.color)).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      durationText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(int.parse(activity.color)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityOptions(BuildContext context) {
    final timeTrackingService = Provider.of<TimeTrackingService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(activity.color)).withOpacity(0.2),
                child: Icon(
                  _getIconData(activity.icon),
                  color: Color(int.parse(activity.color)),
                ),
              ),
              title: Text(
                activity.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Activity options'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Edit Activity'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit screen with activity data
                Navigator.pushNamed(
                  context,
                  '/add_activity',
                  arguments: activity,
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete Activity'),
              onTap: () async {
                Navigator.pop(context);
                // Show confirmation dialog
                final confirmed = await _showDeleteConfirmationDialog(context);
                if (confirmed == true) {
                  final result = await timeTrackingService.deleteActivity(activity.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success'] 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(10),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.name}"? This will also delete all time entries associated with this activity.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'coffee':
        return Icons.coffee;
      case 'food':
        return Icons.restaurant;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.access_time;
    }
  }
}
