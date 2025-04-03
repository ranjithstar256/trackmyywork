import 'package:flutter/material.dart';

class ActiveActivityBanner extends StatelessWidget {
  final String activityName;
  final String activityIcon;
  final Duration elapsed;
  final VoidCallback onStop;

  const ActiveActivityBanner({
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIconData(activityIcon),
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently tracking:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ),
                ),
                Text(
                  '$activityName - $formattedTime',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.stop_circle_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: onStop,
            tooltip: 'Stop tracking',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
