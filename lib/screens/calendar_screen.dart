import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../hive_boxes.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

// --- Theme Colors for Modern Look ---
const Color kPrimaryColor = Color(0xFF4C5BF0); // Modern Blue/Indigo Accent
const Color kLightBackground = Color(0xFFF5F6FA); // Scaffold Background
const Color kTextDark = Color(0xFF1E273A); // Dark text

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Maps keyed by "YYYY-M" (e.g. "2025-12")
  Map<String, List<TransactionModel>> monthlyTx = {};
  Map<String, double> monthlyGoalSavings = {};

  // Currently selected month/year's data
  List<TransactionModel> selectedMonthTx = [];
  double selectedMonthGoalSaved = 0;

  DateTime focusedMonth = DateTime.now();

  late final ValueListenable<Box> _txListenable;
  late final ValueListenable<Box> _goalsListenable;
  
  late Box settingsBox;
  
  // CRITICAL CHANGE: Use a nullable double to represent an unset budget
  double? totalMonthlyBudget; 

  final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  @override
  void initState() {
    super.initState();

    _txListenable = HiveBoxes.getTransactions().listenable();
    _goalsListenable = HiveBoxes.getGoals().listenable();

    settingsBox = Hive.box('settings');
    _loadSettings();

    _txListenable.addListener(_onBoxesChanged);
    _goalsListenable.addListener(_onBoxesChanged);

    _loadData();
    _loadSelectedMonth(focusedMonth.year, focusedMonth.month);
  }

  @override
  void dispose() {
    try {
      _txListenable.removeListener(_onBoxesChanged);
    } catch (_) {}
    try {
      _goalsListenable.removeListener(_onBoxesChanged);
    } catch (_) {}
    super.dispose();
  }

  // UPDATED: Load budget with conversion logic
  void _loadSettings() {
    final incomeType = settingsBox.get('incomeType', defaultValue: 'monthly') as String;
    final monthlyIncome = (settingsBox.get('monthlyIncome', defaultValue: 0) as num).toDouble();
    final weeklyIncome = (settingsBox.get('weeklyIncome', defaultValue: 0) as num).toDouble();

    double? calculatedBudget;

    if (monthlyIncome <= 0 && weeklyIncome <= 0) {
      calculatedBudget = null; // Budget is genuinely unset or zero
    } else if (incomeType == 'monthly') {
      calculatedBudget = monthlyIncome;
    } else if (incomeType == 'weekly') {
      // Apply the conversion factor: 4.33 weeks per month
      calculatedBudget = weeklyIncome * 4.33; 
    } else {
      calculatedBudget = null; // Default case if type is unexpected
    }
    
    setState(() {
      totalMonthlyBudget = calculatedBudget;
    });
  }

  void _onBoxesChanged() {
    _loadSettings();
    _loadData();
    _loadSelectedMonth(focusedMonth.year, focusedMonth.month);
  }

  /// Build maps keyed by "YYYY-M" (no leading zero) so it's consistent with how we query
  void _loadData() {
    final txList = HiveBoxes.getTransactions().values.toList().cast<TransactionModel>();
    final goals = HiveBoxes.getGoals().values.toList().cast<GoalModel>();

    Map<String, List<TransactionModel>> txMap = {};
    Map<String, double> goalMap = {};

    for (var tx in txList) {
      final dt = tx.date;
      if (dt == null) continue;
      final key = "${dt.year}-${dt.month}"; // e.g. "2025-12"
      txMap.putIfAbsent(key, () => []);
      txMap[key]!.add(tx);
    }

    for (var g in goals) {
      final dt = g.startDate;
      if (dt == null) continue;
      final key = "${dt.year}-${dt.month}";
      goalMap[key] = (goalMap[key] ?? 0) + (g.savedAmount ?? 0);
    }

    txMap.forEach((k, list) {
      list.sort((a, b) {
        final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });
    });

    setState(() {
      monthlyTx = txMap;
      monthlyGoalSavings = goalMap;
    });
  }

  void _loadSelectedMonth(int year, int month) {
    final key = "$year-$month";
    setState(() {
      selectedMonthTx = monthlyTx[key] ?? [];
      selectedMonthGoalSaved = monthlyGoalSavings[key] ?? 0.0;
    });
  }

  // Function to show the Date Picker for month selection
  Future<void> _pickMonth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: focusedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "Select Month/Year (Day is ignored)",
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: kTextDark,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => focusedMonth = DateTime(picked.year, picked.month, 1));
      _loadSelectedMonth(focusedMonth.year, focusedMonth.month);
    }
  }


  // ————————————————————— MODERN SUMMARY CARD —————————————————————
  Widget _buildSummaryCard() {
    double expenses = selectedMonthTx.where((tx) => tx.isIncome == false).fold(0.0, (sum, tx) => sum + tx.amount);
    double goalSaved = selectedMonthGoalSaved;

    // CONDITIONAL CALCULATION: Check if budget is set
    double? thisMonthSaved;
    if (totalMonthlyBudget != null) {
      thisMonthSaved = totalMonthlyBudget! - expenses;
    }
    
    // Determine the color for the main 'This month's Saved' value
    Color savedColor = (thisMonthSaved == null) 
        ? Colors.white // Default white if budget is unset
        : (thisMonthSaved >= 0 ? Colors.green.shade300 : Colors.red.shade300); // Lighter colors for contrast on blue

    String savedValueText = (thisMonthSaved == null)
        ? "Budget Not Set"
        : currencyFormatter.format(thisMonthSaved);

    String budgetValueText = (totalMonthlyBudget == null)
        ? "Not Set"
        : currencyFormatter.format(totalMonthlyBudget);

    // ******************** NEW LOGIC START ********************
    String budgetStatusMessage;
    Color statusColor;

    if (totalMonthlyBudget == null) {
      budgetStatusMessage = "Set a budget to track progress!";
      statusColor = Colors.white.withOpacity(0.7);
    } else {
      bool overspent = expenses > totalMonthlyBudget!;
      if (overspent) {
        budgetStatusMessage = "You have overspent on this month!";
        statusColor = Colors.red.shade100;
      } else {
        budgetStatusMessage = "You're on track!";
        statusColor = Colors.green.shade100;
      }
    }
    // ******************** NEW LOGIC END ********************

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Design Enhancement 1: Subtle Gradient and improved Shadow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [kPrimaryColor.withOpacity(0.9), kPrimaryColor.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.4), // Use primary color for shadow glow
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Month Selector & Main Saved Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month selector & main metric (left side)
              Expanded(
                child: GestureDetector(
                  onTap: _pickMonth, // Calls the dedicated month picker function
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Text(
                            // Displays the current month
                            DateFormat.yMMMM().format(focusedMonth),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Changed text color to white
                            ),
                          ),
                          // Design Enhancement 2: Add visual cue that the month name is tappable
                          const Icon(Icons.arrow_drop_down, color: Colors.white, size: 30),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "This Month's Saved",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8), // Lighter hint text
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Design Enhancement 3: Subtle text glow for the main value
                      Text(
                        savedValueText, // Display "Budget Not Set" or currency format
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white, // Main value is bright white
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: savedColor.withOpacity(0.5), // Glow based on the result color
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      
                      // ******************** STATUS MESSAGE INSERTION ********************
                      const SizedBox(height: 8), // Added spacing
                      Text(
                        budgetStatusMessage, // Display status message
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor, // Use calculated status color
                        ),
                      ),
                      // ******************** END STATUS MESSAGE INSERTION ********************
                    ],
                  ),
                ),
              ),

              // Calendar Icon (right side) - Now functional via onTap of the whole left column
              // Design Enhancement 4: Explicitly make the icon tappable too
              InkWell(
                onTap: _pickMonth,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // White transparent background
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 24), // White icon
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          
          // Display the Total Budget for context
          _buildDetailRow(
            "Total Monthly Budget",
            budgetValueText, // Display "Not Set" or currency format
            Colors.white.withOpacity(0.9), // White color for budget in card
            isBold: false, // Make this slightly less prominent
          ),
          
          const Divider(height: 20, thickness: 0.5, color: Colors.white54), // Lighter divider

          // Actual Expenses
          _buildDetailRow(
            "Expenses",
            currencyFormatter.format(expenses),
            Colors.red.shade300, // Lighter red for contrast on blue background
          ),

          // Saved to Goals
          _buildDetailRow(
            "Saved to Goals",
            currencyFormatter.format(goalSaved),
            Colors.amber.shade300, // Lighter amber for contrast
          ),
        ],
      ),
    );
  }

  // Helper widget for card rows
  Widget _buildDetailRow(String title, String value, Color color, {bool isBold = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title, 
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9)) // All label text is light
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: 16
            ),
          ),
        ],
      ),
    );
  }

  // ———————————————————— CALENDAR ICON MARKERS ————————————————————
  Widget _buildDayMarker(DateTime day) {
    final txForDay = selectedMonthTx.where((tx) {
      final d = tx.date;
      if (d == null) return false;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();

    if (txForDay.isEmpty) return const SizedBox();

    bool hasIncome = txForDay.any((tx) => tx.isIncome);
    bool hasExpense = txForDay.any((tx) => !tx.isIncome);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasIncome) const Icon(Icons.arrow_upward, size: 8, color: Colors.green),
          if (hasExpense) const Icon(Icons.arrow_downward, size: 8, color: Colors.red),
        ],
      ),
    );
  }

  // Show transactions for a specific day in a bottom sheet/modal
  void _showDayTransactions(DateTime day) {
    final list = selectedMonthTx.where((tx) {
      final d = tx.date;
      if (d == null) return false;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Design Enhancement 5: Added shape to bottom sheet for a softer look
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 60,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.5)),
              ),
              Text(
                "Transactions on ${DateFormat.yMMMd().format(day)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kTextDark)
              ),
              const SizedBox(height: 12),
              list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, top: 10),
                      child: Text("No transactions recorded for this day.", style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 60, endIndent: 10),
                        itemBuilder: (_, i) {
                          final tx = list[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tx.isIncome ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                tx.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                color: tx.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              tx.title ?? '(No title)',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: kTextDark)
                            ),
                            subtitle: Text(tx.category ?? '', style: TextStyle(color: Colors.grey.shade600)),
                            trailing: Text(
                              "${tx.isIncome ? '+' : '-'}${currencyFormatter.format(tx.amount)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: tx.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                              )
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ————————————————————— UI LAYOUT —————————————————————

  // Custom header to replace the old AppBar (keeps back button)
  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),

          _buildSummaryCard(),

          // CALENDAR CONTAINER
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2100),
                focusedDay: focusedMonth,
                currentDay: DateTime.now(),
                headerVisible: false,
                calendarFormat: CalendarFormat.month,
                availableGestures: AvailableGestures.horizontalSwipe,

                onPageChanged: (d) {
                  setState(() => focusedMonth = DateTime(d.year, d.month, 1));
                  _loadSelectedMonth(focusedMonth.year, focusedMonth.month);
                },

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    focusedMonth = DateTime(focusedDay.year, focusedDay.month, 1);
                  });
                  _loadSelectedMonth(focusedMonth.year, focusedMonth.month);
                  _showDayTransactions(selectedDay);
                },

                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) => _buildDayMarker(day),
                ),

                // Calendar styling (Uses theme colors)
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600),
                  weekdayStyle: const TextStyle(color: kTextDark, fontWeight: FontWeight.w600),
                ),

                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  todayDecoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  selectedDecoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(color: Colors.red.shade400),
                  outsideDaysVisible: false,
                  cellMargin: const EdgeInsets.all(6.0),
                ),
              ),
            ),
          ),
        ],
      ), 
    );
  }
}