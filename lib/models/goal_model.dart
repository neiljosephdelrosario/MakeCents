// lib/models/goal_model.dart
import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 1)
class GoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double savedAmount;

  /// OLD ICON STORAGE
  @HiveField(4)
  int iconCodePoint;

  @HiveField(5)
  DateTime? startDate;

  @HiveField(6)
  DateTime? endDate;

  /// NEW fluent icon name
  @HiveField(7)
  String? iconName; // <-- MAKE IT NULLABLE

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.iconCodePoint = 0xe88a,
    this.startDate,
    this.endDate,
    this.iconName,
  });

  /// 🔥 SAFETY: Old saved items get a default Fluent icon
  String get safeIconName => iconName ?? "home_24_regular";

  bool get isCompleted => savedAmount >= targetAmount;
}
