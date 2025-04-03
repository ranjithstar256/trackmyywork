import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 0)
class Activity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String color;

  @HiveField(3)
  final String icon;

  @HiveField(4)
  final bool isDefault;

  Activity({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.isDefault = false,
  });

  Activity copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    bool? isDefault,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
