import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction_model.dart';
import 'models/goal_model.dart';

class HiveBoxes {
  // Box names
  static const String transactionBox = 'transactions';
  static const String budgetBox = 'budget';
  static const String goalsBox = 'goals';
  static const String settingsBox = 'settings';
  static const String notificationsBox = 'notifications';

  // Helpers to get boxes
  static Box<TransactionModel> getTransactions() => Hive.box<TransactionModel>(transactionBox);
  static Box<GoalModel> getGoals() => Hive.box<GoalModel>(goalsBox);
  static Box getBudget() => Hive.box(budgetBox);
  static Box getSettings() => Hive.box(settingsBox);
  static Box getNotifications() => Hive.box(notificationsBox);
}
  