import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../models/goal_model.dart';
import '../hive_boxes.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'financial_educ_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';

// Define the primary accent color globally for consistent modern theming
const Color primaryAccent = Color(0xFF4C5BF0);

// ADDED: Notification Specific Styles for consistency
const Color kLightBackground = Colors.white; // Pure white background
const Color kTextDark = Colors.black87; 
const Color kWarningColor = Color(0xFFF09A4C); // Orange/Warning
const Color kSuccessColor = Color(0xFF4CAF50); // Green/Success
const Color secondaryAccent = Color(0xFFC7CEFF); // Used for light backgrounds

class _NotificationStyle {
  final IconData icon;
  final Color color;
  _NotificationStyle(this.icon, this.color);
}

// Utility function to categorize the notification based on content
_NotificationStyle _getNotificationStyle(String message) {
  final lowerCaseMessage = message.toLowerCase();
  if (lowerCaseMessage.contains('success') || lowerCaseMessage.contains('added') || lowerCaseMessage.contains('completed')) {
    return _NotificationStyle(Icons.check_circle_rounded, kSuccessColor);
  }
  if (lowerCaseMessage.contains('overspent') || lowerCaseMessage.contains('warning') || lowerCaseMessage.contains('limit') || lowerCaseMessage.contains('exceeded')) {
    return _NotificationStyle(Icons.warning_rounded, kWarningColor);
  }
  if (lowerCaseMessage.contains('reminder') || lowerCaseMessage.contains('due') || lowerCaseMessage.contains('upcoming')) {
    return _NotificationStyle(Icons.alarm_on_rounded, primaryAccent);
  }
  // Default style for general messages
  return _NotificationStyle(Icons.notifications_active_rounded, Colors.blueGrey);
}

// Helper widget for a single modern notification list tile in the dialog
class _ModernNotificationItem extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  // NOTE: isUnread logic is simple for design demo consistency
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
        // Handle tapping (e.g., mark as read, navigate to source)
      },
    );
  }
}

// =========================================================================
// END OF ADDED NOTIFICATION HELPER CLASSES AND WIDGETS
// =========================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late Box goalsBox;
  late Box transactionsBox;
  late Box settingsBox;
  late Box notifBox;

  final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    // Assuming HiveBoxes and goal_model/transactions exist and are correctly implemented
    goalsBox = HiveBoxes.getGoals(); 
    transactionsBox = HiveBoxes.getTransactions();
    settingsBox = Hive.box('settings');
    notifBox = Hive.box('notifications');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ========== FLUENT ICON MAP (Retained) ==========
  IconData resolveFluentIcon(int codePoint) {
    switch (codePoint) {
      case 0xF4C6:
        return FluentIcons.home_24_regular;
      case 0xF39E:
        return FluentIcons.cart_24_regular;
      case 0xF799:
        return FluentIcons.heart_24_regular;
      case 0xF6B1:
        return FluentIcons.airplane_24_regular;
      case 0xF0B1:
        return FluentIcons.book_24_regular;
      case 0xF1AF:
        return FluentIcons.briefcase_24_regular;
      case 0xF2F1:
        return FluentIcons.wallet_24_regular;
      case 0xF4C0:
        return FluentIcons.calendar_24_regular;
      case 0xF4A8:
        return FluentIcons.trophy_24_regular;
      case 0xF6C3:
        return FluentIcons.gift_24_regular;
      case 0xF4D6:
        return FluentIcons.building_24_regular;
      case 0xF6A2:
        return FluentIcons.beach_24_regular;
      case 0xF13A:
        return FluentIcons.music_note_2_24_regular;
      case 0xF3DA:
        return FluentIcons.games_24_regular;
      case 0xF5E9:
        return FluentIcons.device_meeting_room_24_regular;
      case 0xF56C:
        return FluentIcons.camera_24_regular;
      default:
        return FluentIcons.wallet_24_regular;
    }
  }

  // =========================================================================
  // MODERNIZED AND RESPONSIVE _openNotifications DIALOG (Retained)
  // =========================================================================
  void _openNotifications() {
    // Retaining the original Hive logic for fetching
    final List<dynamic> currentDynamic =
        notifBox.get('messages', defaultValue: <dynamic>[]);
    final List<Map<String, dynamic>> notifications = currentDynamic
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        // Sort/Reverse so the newest notification is on top
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
                            // Highlight the first few for design purposes
                            isUnread: i < 3, 
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
                        if(mounted) setState(() {});
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
  // =========================================================================
  // END OF MODERNIZED _openNotifications DIALOG
  // =========================================================================

  // ========== Helpers (Removed _getWeeklyIncome) ==========
  double _extractAmount(dynamic item) {
    try {
      if (item == null) return 0.0;
      if (item is num) return item.toDouble();
      if (item is Map) {
        final v = item['amount'] ?? item['value'];
        if (v is num) return v.toDouble();
      }
      try {
        final v = (item as dynamic).amount;
        if (v is num) return v.toDouble();
      } catch (_) {}
    } catch (_) {}
    return 0.0;
  }

  DateTime? _extractDate(dynamic item) {
    try {
      if (item == null) return null;
      if (item is Map) {
        final d = item['date'];
        if (d is DateTime) return d;
        if (d is String) return DateTime.tryParse(d);
      }
      try {
        final d = (item as dynamic).date;
        if (d is DateTime) return d;
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  String _extractCategory(dynamic item) {
    try {
      if (item == null) return 'Other';
      if (item is Map && item['category'] is String) return item['category'];
      try {
        final c = (item as dynamic).category;
        if (c is String) return c;
      } catch (_) {}
    } catch (_) {}
    return 'Other';
  }

  // Gets the monthly income limit
  double _getMonthlyIncome() {
    try {
      final income = settingsBox.get('monthlyIncome', defaultValue: 0.0);
      if (income is num) return income.toDouble();
    } catch (_) {}
    return 0.0;
  }

  // NOTE: _getWeeklyIncome helper removed as logic is now in build

  double _getTotalSpentThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    double total = 0.0;

    for (var item in transactionsBox.values) {
      final dt = _extractDate(item) ?? DateTime.now();
      // Only sum non-income transactions within the current month
      if (!dt.isBefore(start) && (item as dynamic).isIncome != true) total += _extractAmount(item);
    }
    return total;
  }

  Map<String, double> _getCategoryBreakdownThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final map = <String, double>{};

    for (var item in transactionsBox.values) {
      final dt = _extractDate(item) ?? DateTime.now();
      // Only include non-income transactions in the breakdown
      if (!dt.isBefore(start) && (item as dynamic).isIncome != true) {
        final cat = _extractCategory(item);
        map[cat] = (map[cat] ?? 0) + _extractAmount(item);
      }
    }
    return map;
  }

  List<GoalModel> _getActiveGoals() {
    try {
      // Filter out completed goals and sort by saved amount (descending)
      final goals = goalsBox.values.cast<GoalModel>().where((g) => !g.isCompleted).toList(); 
      goals.sort((a, b) => b.savedAmount.compareTo(a.savedAmount));
      return goals.take(5).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== UI Cards (MODIFIED) ==========

  // MODIFIED: Accepts only spent and budget
  Widget _progressCard(double spent, double budget) { 
    final pct = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final pctLabel = (pct * 100).toStringAsFixed(0);
    final overspent = spent > budget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Modern Gradient: Deep blue or warning red/orange
        gradient: LinearGradient(
          colors: overspent
              ? [const Color(0xFFF75555), const Color(0xFFFFA64F)] 
              : [primaryAccent, primaryAccent.withOpacity(0.8)],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                overspent ? "Budget Exceeded" : "Budget Status",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14),
              ),
            ),
            Icon(overspent ? FluentIcons.warning_24_filled : FluentIcons.checkmark_circle_24_filled,
                color: Colors.white, size: 20), // Fluent Icons
          ]),
          const SizedBox(height: 16),
          Text(
            currency.format(spent),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // MODIFIED: Use generic "Budget Limit"
          Text('of ${currency.format(budget)} Budget Limit', 
              style: const TextStyle(color: Colors.white70)),
          
          const SizedBox(height: 16),
          // Simple Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white38,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text('$pctLabel% Used This Month',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // Modernized Category Row
  Widget _categoryRow(String name, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(
            child: Text(name, 
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
        Text(currency.format(amount),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // Modernized Active Goal Tile
  Widget _activeGoalTile(GoalModel g) {
    final progress = g.targetAmount == 0
        ? 0.0
        : (g.savedAmount / g.targetAmount).clamp(0.0, 1.0);

    final color = progress >= 1
        ? Colors.green.shade600
        : (progress > 0.5 ? Colors.orange.shade600 : primaryAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000), // Very subtle shadow
            blurRadius: 4, 
            offset: Offset(0, 2)
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(resolveFluentIcon(g.iconCodePoint), color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(g.name, 
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              ])),
          const SizedBox(width: 16),
          Text('${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ========== Navigation (Retained) ==========
  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const BudgetScreen()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const FinancialEducScreen()));
        break;
    }
  }

  // Modernized Nav Item (Retained)
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

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat('MMMM yyyy').format(DateTime.now());
    
    // START MODIFICATION FOR BUDGET CALCULATION
    const double weeklyToMonthlyFactor = 4.33; // Constant for weekly to monthly conversion

    double monthlyIncome = _getMonthlyIncome();
    
    // Fetch weekly income safely
    double weeklyIncome = 0.0;
    final weeklyValue = settingsBox.get('weeklyIncome', defaultValue: 0.0);
    // Ensure the retrieved value is treated as a double
    if (weeklyValue is num) {
        weeklyIncome = weeklyValue.toDouble();
    }
    
    // Determine the final budget shown on the card
    double finalBudget = monthlyIncome; // Default to monthlyIncome
    
    // Prioritize weekly income * 4.33 if weeklyIncome is set (> 0)
    if (weeklyIncome > 0) {
        finalBudget = weeklyIncome * weeklyToMonthlyFactor;
    }
    // END MODIFICATION FOR BUDGET CALCULATION
    
    final spent = _getTotalSpentThisMonth();
    final breakdown = _getCategoryBreakdownThisMonth();

    // Check if the boxes are initialized before using them
    if (!goalsBox.isOpen || !transactionsBox.isOpen || !settingsBox.isOpen || !notifBox.isOpen) {
      // Return a loading or error screen if boxes aren't ready
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final activeGoals = _getActiveGoals();

    final sortedCats =
        breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCats = sortedCats.take(4).toList();
    
    // Modernized color palette for categories
    final colors = [
      const Color(0xFF6B72FF), 
      const Color(0xFFFF9900), 
      const Color(0xFF00BFA5), 
      const Color(0xFFD32F2F), 
    ];

    final List<dynamic> notifList =
        notifBox.get('messages', defaultValue: <dynamic>[]);
    final notifCount = notifList.length;

    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ROW (Date, Notifications, Profile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                  Row(
                    children: [
                      Text(monthYear,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
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
                          onPressed: _openNotifications, // CALLS THE NEW MODERN DIALOG
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
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryAccent,
                        child: Icon(FluentIcons.person_24_filled, color: Colors.white, size: 20),
                      ),
                    )
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              // BUDGET PROGRESS CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _progressCard(spent, finalBudget), // Uses finalBudget
              ),
              const SizedBox(height: 24),
              
              // SPENDING BREAKDOWN CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text("Monthly Breakdown",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: const [
                      BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                  Row(children: [
                    // Retained money icon
                    Icon(FluentIcons.money_16_regular, color: primaryAccent, size: 20),
                    const SizedBox(width: 8),
                    const Text("Total Spent",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Spacer(),
                    Text(currency.format(spent),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryAccent)),
                  ]),
                  const Divider(height: 24),
                  
                  // Category Breakdown List
                  Column(
                    children: List.generate(topCats.length, (i) {
                      final e = topCats[i];
                      return _categoryRow(
                          e.key, e.value, colors[i % colors.length]);
                    }),
                  ),
                  if (topCats.isEmpty) ...[
                    _categoryRow('Food', 0.0, colors[0]),
                    _categoryRow('Utilities', 0.0, colors[1]),
                    _categoryRow('Transport', 0.0, colors[2]),
                  ]
                ]),
              ),
              const SizedBox(height: 24),

              // ACTIVE GOALS SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text("Active Goals",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: activeGoals.isEmpty
                      ? [
                            const Text('No active goals yet. Start saving!',
                                style: TextStyle(color: Colors.grey))
                          ]
                        : activeGoals
                            .map((g) => _activeGoalTile(g))
                            .toList(),
                ),
              ),
              const SizedBox(height: 24), 
            ]),
        ),
      ),
      // MODERNIZED Bottom Navigation Bar
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
                _buildNavItem(FluentIcons.ribbon_24_regular, FluentIcons.ribbon_24_filled, "Goals", 1),
                _buildNavItem(FluentIcons.grid_dots_24_regular, FluentIcons.grid_dots_24_filled, "Dashboard", 2),
                _buildNavItem(FluentIcons.book_open_24_regular, FluentIcons.book_open_24_filled, "Education", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}