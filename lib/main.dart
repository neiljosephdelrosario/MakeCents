import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction_model.dart';
import 'models/goal_model.dart';
import 'screens/onboarding_screen.dart';
import 'hive_boxes.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(GoalModelAdapter());
  }
  await Hive.openBox<TransactionModel>(HiveBoxes.transactionBox);
  await Hive.openBox(HiveBoxes.budgetBox);
  await Hive.openBox<GoalModel>(HiveBoxes.goalsBox);
  await Hive.openBox(HiveBoxes.settingsBox);
  await Hive.openBox(HiveBoxes.notificationsBox);
  runApp(const MyApp());  
}

class MyApp extends StatelessWidget { 
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MakeCents',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const OnboardingScreen(),
    );
  }
}
