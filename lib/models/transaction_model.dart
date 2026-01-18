import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1) 
class TransactionModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String category;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isIncome;

  TransactionModel({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}
