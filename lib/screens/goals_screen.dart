// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../hive_boxes.dart';
import 'edit_goal_screen.dart';
import 'add_goal_form.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
import 'financial_educ_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart'; // ADDED: Import for CalendarScreen

// --- Theme Colors for Consistency (Matching BudgetScreen) ---
const Color primaryAccent = Color(0xFF4C5BF0); // The primary accent color 
const Color kLightBackground = Colors.white; // Pure white background
const Color kTextDark = Colors.black87; 

// ADDED: Notification Specific Styles
const Color kWarningColor = Color(0xFFF09A4C); // Orange/Warning
const Color kSuccessColor = Color(0xFF4CAF50); // Green/Success

// Helper class to safely return both icon and color
class _NotificationStyle {
  final IconData icon;
  final Color color;
  _NotificationStyle(this.icon, this.color);
}

// Utility function to categorize the notification based on content
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
  // Default style for general messages
  return _NotificationStyle(Icons.notifications_active_rounded, Colors.blueGrey);
}

// Helper widget for a single modern notification list tile in the dialog
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
      // Highlight unread notifications with a subtle background
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
      onTap: () {
        // Kept empty: No change to logic
      },
    );
  }
}
// END OF ADDED NOTIFICATION WIDGETS

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late Box<GoalModel> goalsBox;
  late Box<TransactionModel> transactionBox;
  late Box settingsBox;
  late TabController _tabController;

  final currencyFormatter =
      NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  int notifCount = 0;

  // navigation state (0: Budget, 1: Goals, 2: Add(center), 3: Dashboard, 4: Education)
  int _selectedIndex = 1;

  // A small fluent icon name -> IconData map (Option A)
  final Map<String, IconData> fluentIconMap = {
    'home': FluentIcons.home_24_regular,
    'cart': FluentIcons.cart_24_regular,
    'heart': FluentIcons.heart_24_regular,
    'airplane': FluentIcons.airplane_24_regular,
    'book': FluentIcons.book_24_regular,
    'briefcase': FluentIcons.briefcase_24_regular,
    'wallet': FluentIcons.wallet_24_regular,
    'calendar': FluentIcons.calendar_24_regular,
    'trophy': FluentIcons.trophy_24_regular,
    'gift': FluentIcons.gift_24_regular,
    'building': FluentIcons.building_24_regular,
    'beach': FluentIcons.beach_24_regular,
    'music': FluentIcons.music_note_2_24_regular,
    'game': FluentIcons.games_24_regular,
    'device': FluentIcons.device_meeting_room_24_regular,
    'camera': FluentIcons.camera_24_regular,
  };

  @override
  void initState() {
    super.initState();
    goalsBox = Hive.box<GoalModel>('goals');
    transactionBox = HiveBoxes.getTransactions();
    settingsBox = Hive.box('settings');
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, double> _getBudgetAllocations() {
    final saved = settingsBox.get('budgetAllocations');
    if (saved == null) return {};
    final Map map = Map<String, dynamic>.from(saved);
    return map.map((key, value) => MapEntry(key as String, (value as num).toDouble()));
  }

  double _getGoalsAllocationAmount() {
    final allocs = _getBudgetAllocations();
    return allocs['Goals'] ?? 0.0;
  }

  double _getGoalsSpentFromTransactions() {
    final txs = transactionBox.values.where((tx) => tx.category == 'Goals' && !tx.isIncome);
    return txs.fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  double _calculateTotalSaved() {
    if (goalsBox.isEmpty) return 0.0;
    return goalsBox.values.fold<double>(0.0, (sum, goal) => sum + goal.savedAmount);
  }

  double _getRemainingGoalsAllocation() {
    final alloc = _getGoalsAllocationAmount();
    final spent = _getGoalsSpentFromTransactions();
    final rem = alloc - spent;
    return rem < 0 ? 0.0 : rem;
  }

  void _openAddGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddGoalForm(onGoalAdded: () => setState(() {})),
      ),
    );
  }

  Widget _goalIcon(GoalModel goal, Color color, {double size = 28}) {
    final name = (goal.iconName ?? '').trim();
    if (name.isNotEmpty) {
      final mapped = fluentIconMap[name]; 
      if (mapped != null) {
        return Icon(mapped, color: color, size: size);
      }
    }

    final cp = goal.iconCodePoint;
    if (cp != 0) {
      try {
        final fluentData = IconData(cp,
            fontFamily: 'FluentSystemIcons', fontPackage: 'fluentui_system_icons');
        return Icon(fluentData, color: color, size: size);
      } catch (_) {}
    }

    return Icon(FluentIcons.wallet_24_regular, color: color, size: size);
  }

  void _openEditGoal(GoalModel goal) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Use SingleChildScrollView inside bottom sheet for small devices
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Savings to "${goal.name}"',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter Amount (₱)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: ElevatedButton.icon(
                          icon: const Icon(FluentIcons.save_24_regular, color: Colors.white),
                          onPressed: () async {
                            final entered =
                                double.tryParse(controller.text.trim()) ?? 0.0;
                            if (entered <= 0) return;

                            final goalsEnabled =
                                settingsBox.get('goalsEnabled', defaultValue: false);

                            if (!goalsEnabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Goals feature is not enabled. Enable it in Budget Allocation.'),
                                ),
                              );
                              return;
                            }

                            final allocs = _getBudgetAllocations();
                            if (!allocs.containsKey('Goals')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No "Goals" category found in Budget Allocation. Please set it first.'),
                                ),
                              );
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const BudgetScreen()),
                              );
                              return;
                            }

                            final remaining = _getRemainingGoalsAllocation();
                            if (entered > remaining) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Not enough allocation'),
                                  content: Text(
                                      'You only have ₱${remaining.toStringAsFixed(0)} remaining in your Goals allocation.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            goal.savedAmount += entered;
                            await goal.save();

                            final txBox = HiveBoxes.getTransactions();
                            txBox.add(TransactionModel(
                              title: 'Saved to ${goal.name}',
                              category: 'Goals',
                              amount: entered,
                              date: DateTime.now(),
                              isIncome: false,
                            ));

                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 12),
                          ),
                          label:
                              const Text('Save', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: OutlinedButton.icon(
                          icon: const Icon(FluentIcons.edit_24_regular),
                          label: const Text('Edit Goal'),
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) => EditGoalScreen(
                                goal: goal,
                                onUpdate: (updatedGoal) async {
                                  goal
                                    ..name = updatedGoal.name
                                    ..targetAmount = updatedGoal.targetAmount
                                    ..iconCodePoint = updatedGoal.iconCodePoint
                                    ..iconName = updatedGoal.iconName
                                    ..startDate = updatedGoal.startDate
                                    ..endDate = updatedGoal.endDate;
                                  await goal.save();
                                  setState(() {});
                                },
                                onDelete: () async {
                                  await goal.delete();
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptEnableGoalsFromGoalsScreen() async {
    final alreadyAsked =
        settingsBox.get('askedGoalsInitial', defaultValue: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable Goals?'),
        content: const Text(
            'Enable Goals so you can allocate money to your goals from Budget Allocation. You will be taken to Budget Allocation to set the Goals amount.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (result == true) {
      settingsBox.put('goalsEnabled', true);
      settingsBox.put('askedGoalsInitial', true);

      final allocs = _getBudgetAllocations();
      if (!allocs.containsKey('Goals')) {
        allocs['Goals'] = 0.0;
        settingsBox.put('budgetAllocations', allocs);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BudgetScreen()),
      );
    } else {
      settingsBox.put('askedGoalsInitial', true);
      settingsBox.put('goalsEnabled', false);
      setState(() {});
    }
  }

  // *************************************************************************************************
  // MODERNIZED AND RESPONSIVE _openNotifications DIALOG
  // *************************************************************************************************
  void _openNotifications() {
    final notifBox = Hive.box('notifications');

    final List<dynamic> currentDynamic =
        notifBox.get('messages', defaultValue: <dynamic>[]);
    final List<Map<String, dynamic>> notifications = currentDynamic
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        // Sort/Reverse so the newest notification is on top, without changing the stored list
        .reversed.toList(); 

    showDialog(
      context: context,
      // Use a custom barrier color for a modern fade effect
      barrierColor: Colors.black.withOpacity(0.4), 
      builder: (_) => Dialog(
        // Modern rounded design
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 15,
        child: Container(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          constraints: const BoxConstraints(
            maxHeight: 400, // Responsive height constraint
            maxWidth: 400, // Responsive width constraint
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
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
              
              // Content
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
                          // Parse timestamp, fallback to now if parsing fails
                          final timestamp = timestampString != null 
                              ? DateTime.tryParse(timestampString) ?? DateTime.now() 
                              : DateTime.now();

                          // Use the new modern item widget
                          return _ModernNotificationItem(
                            message: message,
                            timestamp: timestamp,
                            isUnread: i < 3, // Highlight the first few for design purposes
                          );
                        },
                      ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // LOGIC RETAINED: Clear All
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
  // *************************************************************************************************
  // END OF MODERNIZED _openNotifications DIALOG
  // *************************************************************************************************


  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BudgetScreen()),
      );
    } else if (index == 1) {
      // stay
    } else if (index == 2) {
      final goalsEnabled = settingsBox.get('goalsEnabled', defaultValue: false);
      if (goalsEnabled) {
        _openAddGoalSheet();
      } else {
        _promptEnableGoalsFromGoalsScreen();
      }
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FinancialEducScreen()),
      );
    }
  }

  /// Modernized Nav Item (Matching BudgetScreen)
  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? activeIcon : icon, 
            color: isActive ? primaryAccent : Colors.grey.shade600, 
            size: 26),
          Text(label,
              style: TextStyle(
                color: isActive ? primaryAccent : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy').format(now);

    final goalsEnabled = settingsBox.get('goalsEnabled', defaultValue: false);
    final goalsAllocation = _getGoalsAllocationAmount();
    final totalSaved = _calculateTotalSaved();
    final remaining = (goalsAllocation - totalSaved) < 0 ? 0.0 : (goalsAllocation - totalSaved);
    final remainingAlloc = _getRemainingGoalsAllocation();

    // Responsive multipliers
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final baseFont = (width / 380).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: kLightBackground, // Use modern background
      floatingActionButton: goalsEnabled
          ? FloatingActionButton(
              onPressed: _openAddGoalSheet,
              backgroundColor: primaryAccent, // Use primary accent color
              child: const Icon(FluentIcons.add_24_filled, color: Colors.white), // Use fluent icon
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.015),
          child: ValueListenableBuilder(
            valueListenable: goalsBox.listenable(),
            builder: (context, Box<GoalModel> box, _) {
              final goals = box.values.toList();

              final completed = goals.where((g) => g.isCompleted).toList();
              final inProgress = goals
                  .where((g) =>
                      !g.isCompleted &&
                      g.savedAmount > 0 &&
                      g.savedAmount < g.targetAmount)
                  .toList();
              final pending = goals
                  .where((g) => g.savedAmount == 0 && !g.isCompleted)
                  .toList();

              // Use Column/Expanded pattern for correct constraint handling
              return Column( 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with month and notifications/avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT SIDE: Month/Year and Calendar Icon
                      Flexible( // FIX: Use Flexible to restrict width of this entire group
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible( // FIX: Flexible on Text to ensure it truncates and doesn't push the bounds
                              child: Text( 
                                monthYear,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * baseFont,
                                  color: kTextDark, // Use kTextDark
                                ),
                                overflow: TextOverflow.ellipsis, // Added overflow handling
                              ),
                            ),
                            SizedBox(width: width * 0.02),
                            // ADDED: Functional Calendar Icon with Navigation
                            IconButton(
                              onPressed: () {
                                // Navigation push to CalendarScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                                );
                              },
                              icon: const Icon(FluentIcons.calendar_ltr_24_regular, color: primaryAccent, size: 24), 
                              tooltip: "View Calendar",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      
                      // RIGHT SIDE: Notification and Profile Avatar
                      Row( 
                        mainAxisSize: MainAxisSize.min, // Ensure the right side takes minimum space
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  FluentIcons.alert_24_regular, // Fluent Icon
                                  color: primaryAccent, // Use primary accent color
                                  size: 24,
                                ),
                                onPressed: _openNotifications,
                              ),
                              // only show badge if > 0
                              if (notifCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      notifCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(width: width * 0.015),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                            },
                            child: const CircleAvatar(
                              radius: 20, // Slightly larger avatar
                              backgroundColor: primaryAccent, // Use primaryAccent
                              child: Icon(FluentIcons.person_24_filled, color: Colors.white, size: 20), // Fluent filled icon
                            ),
                          )
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.02),
                  
                  // Info Card - Monthly Savings Budget (MODERN REDESIGN)
                  Container(
                    padding: EdgeInsets.all(width * 0.05), // Slightly more padding
                    decoration: BoxDecoration(
                      // Use the modern gradient from the Dashboard/BudgetScreen
                      gradient: LinearGradient(
                        colors: [primaryAccent, primaryAccent.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20), // Increased radius
                      boxShadow: [
                        BoxShadow(
                            color: primaryAccent.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align to start
                      children: [
                        Text(
                          'Monthly Savings Budget',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8), // Faded white
                              fontWeight: FontWeight.w500,
                              fontSize: 14 * baseFont),
                        ),
                        SizedBox(height: height * 0.01),
                        Text(
                          currencyFormatter.format(goalsAllocation),
                          style: TextStyle(
                            fontSize: 32 * baseFont,
                            fontWeight: FontWeight.w900, // Make it thicker
                            color: Colors.white, // Pure white
                          ),
                        ),
                        SizedBox(height: height * 0.012),
                        // Button changed to solid white contrast button
                      
                          
                        SizedBox(height: height * 0.015),
                        
                        // Stats section - colors changed to white
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Assigned to Goals',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13 * baseFont)),
                            Text(
                              currencyFormatter.format(totalSaved),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 13 * baseFont),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.008),
                        // Progress bar color remains white for high contrast
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: goalsAllocation == 0
                                ? 0
                                : (totalSaved / goalsAllocation).clamp(0.0, 1.0),
                            minHeight: (10 * baseFont).clamp(6.0, 14.0),
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), 
                          ),
                        ),
                        SizedBox(height: height * 0.012),
                        // Remaining Savings
                        
                        SizedBox(height: height * 0.008),
                        // Allocation Remaining (budget)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Goals Allocation Remaining',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12 * baseFont)),
                            Text(
                              currencyFormatter.format(remainingAlloc),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12 * baseFont),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // Goals section (locked or tabs)
                  if (!goalsEnabled) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(width * 0.06), // More padding
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.08), // Use accent color light background
                        borderRadius: BorderRadius.circular(20), // Increased radius
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(FluentIcons.lock_closed_24_regular, size: (44 * baseFont).clamp(36.0, 48.0), color: primaryAccent), // Fluent Icon and accent color
                          SizedBox(height: height * 0.01),
                          Text(
                            'Goals is Locked',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 * baseFont, color: kTextDark),
                          ),
                          SizedBox(height: height * 0.008),
                          Text(
                            'Enable Goals to allocate a specific budget for your savings/goals.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13 * baseFont),
                          ),
                          SizedBox(height: height * 0.015),
                          ElevatedButton(
                            onPressed: _promptEnableGoalsFromGoalsScreen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Enable Goals'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Text('My Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 * baseFont)),
                    SizedBox(height: height * 0.01),
                    Center(child: Text('Goals are locked. Enable Goals to add or save to goals.', style: TextStyle(color: Colors.grey, fontSize: 14 * baseFont))),
                    // Use a Spacer to push the content to the top
                    const Spacer(),
                  ] else ...[
                    Text('My Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 * baseFont, color: kTextDark)),
                    SizedBox(height: height * 0.012),
                    // Tab bar
                    Container(
                      constraints: BoxConstraints(maxWidth: width),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: primaryAccent, // Use accent color
                        labelColor: primaryAccent, // Use accent color
                        unselectedLabelColor: Colors.grey,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 4.0,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Completed'),
                          Tab(text: 'In Progress'),
                          Tab(text: 'Pending'),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.012),

                    // FIX: Expanded used to constrain the TabBarView to the remaining height
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGoalList(completed),
                          _buildGoalList(inProgress),
                          _buildGoalList(pending),
                        ],
                      ),
                    ),
                  ],

                  // Spacer added to ensure content doesn't sit on the bottom nav bar
                  SizedBox(height: height * 0.015),
                ],
              );
            },
          ),
        ),
      ),

      // BOTTOM NAVIGATION BAR (MODERN REDESIGN)
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
                // Index 0: Budget
                _buildNavItem(FluentIcons.wallet_24_regular, FluentIcons.wallet_24_filled, "Budget", 0),
                SizedBox(width: MediaQuery.of(context).size.width * 0.13),
                _buildNavItem(FluentIcons.ribbon_24_regular, FluentIcons.ribbon_24_filled, "Goals", 1),
                
                // Placeholder for FAB notch
                const Spacer(),

                // Index 3: Dashboard
                _buildNavItem(FluentIcons.grid_dots_24_regular, FluentIcons.grid_dots_24_filled, "Dashboard", 3),
                SizedBox(width: MediaQuery.of(context).size.width * 0.08),
                _buildNavItem(FluentIcons.book_open_24_regular, FluentIcons.book_open_24_filled, "Education", 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalList(List<GoalModel> goals) {
    if (goals.isEmpty) {
      return const Center(
          child: Text('No goals yet.',
              style: TextStyle(color: Colors.grey, fontSize: 14)));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final mq = MediaQuery.of(context);
      final baseFont = (mq.size.width / 380).clamp(0.85, 1.25);

      return ListView.builder(
        // IMPORTANT: ListView.builder inside TabBarView should have no primary/shrinkwrap properties
        // as the parent Expanded widget constrains it.
        padding: EdgeInsets.zero,
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          final progress = goal.targetAmount <= 0
              ? 0.0
              : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
              
          // Use modern colors for progress indicators
          final color = goal.isCompleted
              ? Colors.green.shade600 // Deeper green for completion
              : progress > 0.8
                  ? Colors.orange.shade700 // Deeper orange for near complete
                  : primaryAccent; // Use primaryAccent for in-progress

          return GestureDetector(
            onTap: () => _openEditGoal(goal),
            child: Container( // MODERN CONTAINER STYLE
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all((16.0 * baseFont).clamp(12.0, 24.0)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // Increased border radius
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [ // Added subtle shadow
                  BoxShadow(color: primaryAccent.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1), // Accent color with low opacity
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: _goalIcon(goal, color, size: 28)), // Larger icon
                      ),
                      SizedBox(width: 12 * baseFont),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, // Bolder title
                                  fontSize: 16 * baseFont,
                                  color: kTextDark),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            // Combined Target and Saved info
                            Text(
                                'Saved: ${currencyFormatter.format(goal.savedAmount)} / Target: ${currencyFormatter.format(goal.targetAmount)}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13 * baseFont), // Slightly darker grey
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900, // Very bold percentage
                              fontSize: 16 * baseFont)),
                    ],
                  ),
                  const SizedBox(height: 12), // More space before progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10, // Thicker progress bar
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}