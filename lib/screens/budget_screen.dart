import 'dart:math' as math;
import 'package:flutter/material.dart';
// Import the Fluent UI icons package to match the Dashboard screen
import 'package:fluentui_system_icons/fluentui_system_icons.dart'; 
import 'package:pie_chart/pie_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../hive_boxes.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_modal.dart';
import 'edit_budget_screen.dart';
import 'goals_screen.dart';
import 'dashboard_screen.dart';
import 'financial_educ_screen.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'ai_budget_screen.dart'; 
import 'calendar_screen.dart'; 

// --- Theme Colors for Consistency (Matching Dashboard) ---
const Color primaryAccent = Color(0xFF4C5BF0); 
const Color kLightBackground = Colors.white; 
const Color kTextDark = Colors.black87; 
const Color kWarningColor = Color(0xFFF09A4C); 
const Color kSuccessColor = Color(0xFF4CAF50); 

class _NotificationStyle {
  final IconData icon;
  final Color color;
  _NotificationStyle(this.icon, this.color);
}

_NotificationStyle _getNotificationStyle(String message) {
  final lowerCaseMessage = message.toLowerCase();
  if (lowerCaseMessage.contains('success') || lowerCaseMessage.contains('added')) {
    return _NotificationStyle(Icons.check_circle_rounded, kSuccessColor);
  }
  if (lowerCaseMessage.contains('overspent') || lowerCaseMessage.contains('warning') || lowerCaseMessage.contains('limit')) {
    return _NotificationStyle(Icons.warning_rounded, kWarningColor);
  }
  if (lowerCaseMessage.contains('reminder') || lowerCaseMessage.contains('due')) {
    return _NotificationStyle(Icons.alarm_on_rounded, primaryAccent);
  }
  return _NotificationStyle(Icons.notifications_active_rounded, Colors.blueGrey);
}

class _ModernNotificationItem extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final bool isUnread; 

  const _ModernNotificationItem({
    required this.message,
    required this.timestamp,
    required this.isUnread,
  });

  String _formatTime(DateTime time) {
    return DateFormat('MMM d, hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final style = _getNotificationStyle(message);

    return ListTile(
      tileColor: isUnread ? style.color.withOpacity(0.05) : null,
      leading: Icon(style.icon, color: style.color, size: 24),
      title: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
          color: kTextDark,
        ),
      ),
      subtitle: Text(
        _formatTime(timestamp),
        style: TextStyle(fontSize: 11, color: kTextDark.withOpacity(0.6)),
      ),
    );
  }
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with WidgetsBindingObserver {
 
  double monthlyIncome = 0; 
  bool _overspentNotified = false;

  late Box notifBox;
  late Box settingsBox;

  Map<String, double> budgetAllocations = {};
  int _selectedIndex = 0; 
 
  String incomeType = "monthly"; 
  final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notifBox = Hive.box('notifications'); 
    settingsBox = Hive.box('settings');   
    _loadIncome(); 
    _loadBudgetAllocations();
    _resetMonthlyExpenses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _resetMonthlyExpenses() {
    final now = DateTime.now();
    final lastResetMonth = settingsBox.get('lastResetMonth', defaultValue: 0);
    final lastResetYear = settingsBox.get('lastResetYear', defaultValue: 0);

    if (lastResetMonth != now.month || lastResetYear != now.year) {
      
      settingsBox.put('lastResetMonth', now.month);
      settingsBox.put('lastResetYear', now.year); 
      _addNotification("New month started. Monthly expense tracking has been reset.");
    }
  }

  void _loadIncome() {
    final newIncomeType = settingsBox.get('incomeType', defaultValue: 'monthly');
    final savedMonthly = (settingsBox.get('monthlyIncome', defaultValue: 0) as num).toDouble();
    final savedWeekly = (settingsBox.get('weeklyIncome', defaultValue: 0) as num).toDouble();

    if (incomeType != newIncomeType || monthlyIncome == 0) { 
        setState(() {
            incomeType = newIncomeType;
            if (incomeType == 'monthly') {
                monthlyIncome = savedMonthly;
            } else {
                monthlyIncome = savedWeekly * 4.33; 
            }
        });
    }
  }

  void _saveIncome(double value) {
    if (incomeType == 'monthly') {
      settingsBox.put('monthlyIncome', value);
    } else {
      settingsBox.put('weeklyIncome', value); 
    }
    
    _addNotification(
        "${incomeType == 'monthly' ? 'Monthly' : 'Weekly'} income updated to ₱${value.toStringAsFixed(0)}");
    
    // This is safe because it's called after a user interaction (not during build).
    // It also causes the ValueListenableBuilder to automatically rebuild with new data.
    _loadIncome(); 
  }

  void _loadBudgetAllocations() {
    final saved = settingsBox.get('budgetAllocations');
    if (saved != null) {
      final Map map = Map<String, dynamic>.from(saved);
      budgetAllocations = map.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()));
    } else {
      budgetAllocations = {};
    }

    final goalsEnabled = settingsBox.get('goalsEnabled', defaultValue: false);
    if (goalsEnabled && !budgetAllocations.containsKey('Goals')) {
      budgetAllocations['Goals'] = 0.0;
      settingsBox.put('budgetAllocations', budgetAllocations);
    }

    setState(() {});
  }

  void _saveBudgetAllocations(Map<String, double> newAllocations) {
    final goalsEnabled = settingsBox.get('goalsEnabled', defaultValue: false);
    if (goalsEnabled && !newAllocations.containsKey('Goals')) {
      newAllocations['Goals'] = 0.0;
    }

    settingsBox.put('budgetAllocations', newAllocations);

    setState(() {
      budgetAllocations = Map<String, double>.from(newAllocations);
    });
    _addNotification("Budget allocations updated.");
  }

  void _addTransaction(String title, String category, double amount, bool isIncome) {
    final box = HiveBoxes.getTransactions();
    box.add(TransactionModel(
      title: title,
      category: category,
      amount: amount,
      date: DateTime.now(),
      isIncome: isIncome,
    ));
  }

  void _editTransaction(TransactionModel tx, String title, String category, double amount, bool isIncome) {
    tx.title = title;
    tx.category = category;
    tx.amount = amount;
    tx.isIncome = isIncome;
    tx.save();
  }

  void _deleteTransaction(TransactionModel tx) {
    tx.delete();
  }

  void _addNotification(String message) {
    final List<dynamic> currentDynamic = notifBox.get('messages', defaultValue: <dynamic>[]);
    final List<Map<String, dynamic>> current = currentDynamic
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    current.add({
      "message": message,
      "timestamp": DateTime.now().toIso8601String(),
    });
    notifBox.put('messages', current);
    setState(() {});
  }

  void _showModernMessage(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.alert_12_filled, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color.withOpacity(0.9),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.5, 
          right: 20,
          left: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
  
  void _openNotifications() {
    final List<dynamic> currentDynamic = notifBox.get('messages', defaultValue: <dynamic>[]);
    
    final List<Map<String, dynamic>> notifications = currentDynamic
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        .reversed
        .toList(); 

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4), 
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 15,
        child: Container(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          constraints: const BoxConstraints(
            maxHeight: 400, 
            maxWidth: 400, 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Alerts & Notifications",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
              
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Text(
                          "No new alerts. All clear!", 
                          style: TextStyle(color: kTextDark.withOpacity(0.5)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        itemBuilder: (_, i) {
                          final notif = notifications[i];
                          final message = notif["message"] ?? '';
                          final timestampString = notif["timestamp"];
                          final timestamp = timestampString != null 
                              ? DateTime.tryParse(timestampString) ?? DateTime.now() 
                              : DateTime.now();

                          return _ModernNotificationItem(
                            message: message,
                            timestamp: timestamp,
                            isUnread: i < 3, 
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        notifBox.put('messages', <Map<String, dynamic>>[]);
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Clear All",
                        style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: primaryAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkOverspending(Box<TransactionModel> box) {
    if (_overspentNotified) return;

    bool overspentFound = false;
    for (var entry in budgetAllocations.entries) {
      String category = entry.key;
      double allocated = entry.value;

      double spent = box.values
          .where((tx) =>
              tx.category == category &&
              !tx.isIncome &&
              tx.date.month == DateTime.now().month &&
              tx.date.year == DateTime.now().year)
          .fold(0.0, (sum, tx) => sum + tx.amount);

      if (spent > allocated) {
        overspentFound = true;
        _addNotification("Time for a Budget Check on $category! Keep on track.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Time for a Budget Check on $category! Keep on track."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    if (overspentFound) {
      setState(() {
        _overspentNotified = true;
      });
    }
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1: 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GoalsScreen()),
        );
        break;
      case 2: 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        break;
      case 3: 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinancialEducScreen()),
        );
        break;
    }
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? activeIcon : icon, 
            color: selected ? primaryAccent : Colors.grey.shade600, 
            size: 26),
          Text(label,
              style: TextStyle(
                color: selected ? primaryAccent : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressBar(String category, double allocated, double spent, Color color) {
    final progress = allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;
    final isOverspent = spent > allocated;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                '${currency.format(spent)} / ${currency.format(allocated)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isOverspent ? Colors.red.shade600 : kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat('MMMM yyyy').format(DateTime.now());
    final List<dynamic> notifList =
        notifBox.get('messages', defaultValue: <dynamic>[]);
    final notifCount = notifList.length;

    return Scaffold(
      backgroundColor: kLightBackground, 
      body: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(),
        builder: (context, Box settings, _) {
          
          final localIncomeType = settings.get('incomeType', defaultValue: 'monthly') as String;
          final localSavedMonthly = (settings.get('monthlyIncome', defaultValue: 0) as num).toDouble();
          final localSavedWeekly = (settings.get('weeklyIncome', defaultValue: 0) as num).toDouble();
          
          // 1. CONVERTED MONTHLY BASE INCOME (Used for ALL calculations: allocations, overspent, pie chart)
          double localMonthlyIncomeBase;
          if (localIncomeType == 'monthly') {
              localMonthlyIncomeBase = localSavedMonthly;
          } else {
              // The weekly to monthly conversion logic (4.33 weeks per month)
              localMonthlyIncomeBase = localSavedWeekly * 4.33; 
          }
          
          // 2. DISPLAY BASE INCOME (Raw input value, used ONLY for the main budget card display)
          // This value will be 1500 if income is weekly
          double budgetCardDisplayBaseIncome = localIncomeType == 'monthly' 
              ? localSavedMonthly
              : localSavedWeekly;

          // Update the global state variable for the dialogs, only if needed. 
          // We rely on initState and _saveIncome to keep the state's incomeType current for the dialog.
          // We will use localIncomeType for all calculations and displays in the UI.

          // ***************************************************************

          Map<String, double> currentAllocations;
          final saved = settings.get('budgetAllocations');
          if (saved != null) {
            final Map map = Map<String, dynamic>.from(saved);
            currentAllocations = map.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()));
          } else {
            currentAllocations = Map<String, double>.from(budgetAllocations);
          }

          final goalsEnabled = settings.get('goalsEnabled', defaultValue: false);
          if (goalsEnabled && !currentAllocations.containsKey('Goals')) {
            currentAllocations['Goals'] = 0.0;
          }

          return ValueListenableBuilder(
            valueListenable: HiveBoxes.getTransactions().listenable(),
            builder: (context, Box<TransactionModel> box, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkOverspending(box);
              });

              // NOTE: Budget screen still filters for current month only
              double totalExpenses = box.values
                  .where((tx) =>
                      !tx.isIncome &&
                      tx.date.month == DateTime.now().month &&
                      tx.date.year == DateTime.now().year)
                  .fold(0.0, (sum, tx) => sum + tx.amount);

              // NOTE: Budget screen still filters for current month only
              double totalIncomes = box.values
                  .where((tx) =>
                      tx.isIncome &&
                      tx.date.month == DateTime.now().month &&
                      tx.date.year == DateTime.now().year)
                  .fold(0.0, (sum, tx) => sum + tx.amount);

              
              double totalBudget = localMonthlyIncomeBase + totalIncomes;

              double budgetCardDisplayTotal = budgetCardDisplayBaseIncome + totalIncomes;

              double percentageUsed = totalBudget > 0 ? (totalExpenses / totalBudget).clamp(0.0, 1.0) : 0.0;
              final overspent = totalExpenses > totalBudget;


              final transactions = box.values
                  .where((tx) =>
                      tx.date.month == DateTime.now().month &&
                      tx.date.year == DateTime.now().year)
                  .toList()
                  .reversed
                  .toList();
              
              final categoryColors = [
                const Color(0xFFD32F2F), 
                const Color(0xFF6B72FF), 
                const Color(0xFF00BFA5), 
                const Color(0xFFFF9900), 
                const Color(0xFFA1887F), 
                const Color(0xFF4DD0E1), 
              ];
              
              final dataMap = Map.fromEntries(
                currentAllocations.entries
                    .where((entry) => entry.value > 0),
              );
              
              final pieChartColors = categoryColors.take(dataMap.length).toList();


              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ******************** HEADER ROW ********************
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                          Row(
                            children: [
                              Text(monthYear,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18, color: kTextDark)),
                              const SizedBox(width: 8), 
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                                  );
                                },
                                icon: const Icon(FluentIcons.calendar_ltr_24_regular, color: primaryAccent, size: 24), 
                                tooltip: "View Calendar",
                              ),
                            ],
                          ),
                          Row(children: [
                            Stack(clipBehavior: Clip.none, children: [
                              IconButton(
                                  icon: const Icon(FluentIcons.alert_24_regular, size: 24),
                                  onPressed: _openNotifications,
                                  color: primaryAccent),
                              if (notifCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.red, shape: BoxShape.circle),
                                    child: Text(notifCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10)),
                                  ),
                                ),
                            ]),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: primaryAccent,
                                child: Icon(FluentIcons.person_24_filled, color: Colors.white, size: 20),
                              ),
                            ),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // ******************** TOP BUDGET CARD ********************
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: overspent
                                  ? [const Color(0xFFF75555), const Color(0xFFFFA64F)] 
                                  : [primaryAccent, primaryAccent.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20), 
                            boxShadow: [
                              BoxShadow(
                                  color: primaryAccent.withOpacity(0.3), 
                                  blurRadius: 15, 
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    // DISPLAY CHANGE: Use the raw type label
                                    "${localIncomeType == 'monthly' ? "This Month's" : "This Week's"} Budget", 
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  GestureDetector(
                                    onTap: _showEditIncomeDialog, 
                                    child: const Icon(FluentIcons.edit_24_regular,
                                        color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  // DISPLAY CHANGE: Use the raw or monthly amount + transaction incomes
                                  currency.format(budgetCardDisplayTotal),
                                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // ******************** BUDGET ALLOCATION SECTION ********************
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Budget Allocation",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: kTextDark,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AiBudgetScreen()),
                                );
                              },
                              icon: const Icon(FluentIcons.sparkle_24_regular, size: 18), 
                              label: const Text("AI Budget Smarter"),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // PIE CHART WIDGET
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: PieChart(
                          dataMap: dataMap.isEmpty ? {'No Allocation': 1.0} : dataMap,
                          animationDuration: const Duration(milliseconds: 800),
                          chartLegendSpacing: 40,
                          chartRadius: math.min(MediaQuery.of(context).size.width / 2.5, 200),
                          colorList: dataMap.isEmpty 
                              ? [Colors.grey.shade300] 
                              : pieChartColors,
                          initialAngleInDegree: 0,
                          chartType: ChartType.disc,
                          ringStrokeWidth: 32,
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: true,
                            decimalPlaces: 1,
                            showChartValueBackground: false,
                            chartValueStyle: TextStyle( 
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                          ),
                          legendOptions: const LegendOptions(
                            showLegendsInRow: true,
                            legendPosition: LegendPosition.bottom,
                            showLegends: true,
                            legendTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            legendShape: BoxShape.circle,
                          ),
                          baseChartColor: Colors.grey.shade100, 
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Add/Edit Allocation Button 
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          onPressed: () async {
                            final newAllocations = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditBudgetScreen(
                                  currentAllocations: currentAllocations,
                                  // PASSES THE CONVERTED MONTHLY BASE INCOME FOR ALLOCATION
                                  monthlyIncome: localMonthlyIncomeBase, 
                                ),
                              ),
                            );
                            if (newAllocations != null) {
                              _saveBudgetAllocations(Map<String, double>.from(newAllocations));
                            }
                          },
                          icon: const Icon(FluentIcons.edit_24_regular, size: 18),
                          label: const Text("Add/Edit Budget Allocation"),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryAccent,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24), 

                      // Category Bars List 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: List.generate(currentAllocations.length, (i) {
                            final entry = currentAllocations.entries.elementAt(i);
                            String category = entry.key;
                            double allocated = entry.value;

                            double spent = box.values
                                .where((tx) =>
                                    tx.category == category &&
                                    !tx.isIncome &&
                                    tx.date.month == DateTime.now().month &&
                                    tx.date.year == DateTime.now().year)
                                .fold(0.0, (sum, tx) => sum + tx.amount);

                            final color = categoryColors[i % categoryColors.length];

                            return _buildCategoryProgressBar(category, allocated, spent, color);
                          }),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Recent Expenses Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: const Text(
                          "Recent Expenses",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kTextDark),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Recent transactions list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: transactions.isEmpty
                            ? const Center(child: Text("No Expenses yet.", style: TextStyle(color: Colors.grey)))
                            : Column(
                                children: transactions.take(5).map((tx) {
                                  final isIncome = tx.isIncome;
                                  final iconColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;
                                  final iconBg = isIncome ? Colors.green.shade50 : Colors.red.shade50;
                                  final amountText = "${isIncome ? '+' : '-'} ${currency.format(tx.amount)}";
                                  final tileIcon = isIncome ? FluentIcons.arrow_bidirectional_left_right_16_regular : FluentIcons.arrow_down_24_filled;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade100),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                      leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: iconBg,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(tileIcon, color: iconColor, size: 24),
                                        ),
                                      title: Text(
                                        tx.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        "${tx.category} • ${DateFormat('MMM d').format(tx.date)}",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Text(
                                        amountText, 
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: iconColor,
                                        ),
                                      ),
                                      onLongPress: () => _showTransactionOptions(tx),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryAccent, 
        onPressed: () {
          if (budgetAllocations.isEmpty) {
            _showModernMessage("Please add a budget category first.", kWarningColor);
          } else {
            showModalBottomSheet(
              context: context,
              builder: (_) => TransactionModal(
                onAdd: _addTransaction,
                categories: budgetAllocations.keys.toList(),
              ),
            );
          }
        },
        child: const Icon(FluentIcons.add_24_filled, color: Colors.white), 
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ******************** BOTTOM NAVIGATION BAR ********************
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
                color: primaryAccent.withOpacity(0.1), 
                blurRadius: 15, 
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(FluentIcons.wallet_24_regular, FluentIcons.wallet_24_filled, "Budget", 0),
                SizedBox(width: MediaQuery.of(context).size.width * 0.13),
                _buildNavItem(FluentIcons.ribbon_24_regular, FluentIcons.ribbon_24_filled, "Goals", 1),
                
                const Spacer(),

                _buildNavItem(FluentIcons.grid_dots_24_regular, FluentIcons.grid_dots_24_filled, "Dashboard", 2),
                SizedBox(width: MediaQuery.of(context).size.width * 0.08),
                _buildNavItem(FluentIcons.book_open_24_regular, FluentIcons.book_open_24_filled, "Education", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ------------------- DIALOGS -------------------
  
  void _showEditIncomeDialog() {
    // This relies on the state variable 'incomeType' being correctly set by _loadIncome
    final String dialogTitle = "Edit ${incomeType == 'monthly' ? 'Monthly' : 'Weekly'} Income";
    
    final double currentRawIncome = (settingsBox.get(
      incomeType == 'monthly' ? 'monthlyIncome' : 'weeklyIncome', 
      defaultValue: 0.0,
    ) as num).toDouble();
    
    final controller = TextEditingController(text: currentRawIncome.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(dialogTitle), 
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Enter new ${incomeType} amount"), 
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                _saveIncome(newValue); 
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Income"),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter amount"),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                _addTransaction("Additional Income", "Income", value, true);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showTransactionOptions(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FluentIcons.edit_24_regular),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(context);
                _showEditTransactionDialog(tx);
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.delete_24_regular, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteTransaction(tx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionDialog(TransactionModel tx) {
    final titleController = TextEditingController(text: tx.title);
    final amountController = TextEditingController(text: tx.amount.toString());
    String selectedCategory = tx.category;
    bool isIncome = tx.isIncome;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Expense"),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: budgetAllocations.keys
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) selectedCategory = v;
                  },
                  decoration: const InputDecoration(labelText: "Category"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text);
              if (title.isNotEmpty && amount != null) {
                _editTransaction(tx, title, selectedCategory, amount, isIncome);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}