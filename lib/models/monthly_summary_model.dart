import 'package:hive/hive.dart';

part 'monthly_summary_model.g.dart';

@HiveType(typeId: 20)
class MonthlySummaryModel extends HiveObject {
  @HiveField(0)
  String monthKey; // e.g. "2025-01"

  @HiveField(1)
  double income;

  @HiveField(2)
  double expenses;

  @HiveField(3)
  double goalSavings;

  @HiveField(4)
  double net;

  MonthlySummaryModel({
    required this.monthKey,
    required this.income,
    required this.expenses,
    required this.goalSavings,
    required this.net,
  });
}
