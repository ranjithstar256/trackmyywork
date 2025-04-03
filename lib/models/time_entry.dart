import 'package:hive/hive.dart';

part 'time_entry.g.dart';

@HiveType(typeId: 1)
class TimeEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String activityId;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime? endTime;

  @HiveField(4)
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
}
