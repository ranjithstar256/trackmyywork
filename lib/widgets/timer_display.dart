import 'package:flutter/material.dart';
import 'dart:math' as math;

class TimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final String activityName;

  const TimerDisplay({
    super.key,
    required this.elapsed,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    final hours = elapsed.inHours;
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    
    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Currently tracking: $activityName',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(context, hours.toString(), 'hours'),
              _buildSeparator(context),
              _buildTimeUnit(context, minutes, 'min'),
              _buildSeparator(context),
              _buildTimeUnit(context, seconds, 'sec'),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (elapsed.inSeconds % 60) / 60,
            backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(BuildContext context, String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
