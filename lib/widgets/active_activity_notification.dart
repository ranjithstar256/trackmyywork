import 'package:flutter/material.dart';
import '../services/time_tracking_service.dart';

class ActiveActivityNotification extends StatelessWidget {
  final String activityName;
  final String activityIcon;
  final Duration elapsed;
  final VoidCallback onStop;

  const ActiveActivityNotification({
    Key? key,
    required this.activityName,
    required this.activityIcon,
    required this.elapsed,
    required this.onStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the elapsed time
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final formattedTime = 
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Activity icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(activityIcon),
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Activity name and timer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Stop button
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            color: Theme.of(context).colorScheme.error,
            onPressed: onStop,
            tooltip: 'Stop tracking',
          ),
        ],
      ),
    );
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
