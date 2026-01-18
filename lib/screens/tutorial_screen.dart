import 'package:flutter/material.dart';
import 'package:makecents_capstone/tutorial/budget_planning_tutorial.dart';
import 'package:makecents_capstone/tutorial/goal_setting_tutorial.dart';
import 'package:makecents_capstone/tutorial/dashboard_tutorial.dart';
import 'package:makecents_capstone/tutorial/financial_tutorial.dart';

// --- Theme Colors for Modern Look (Matching CalendarScreen) ---
const Color kPrimaryColor = Color(0xFF4C5BF0); // Modern Blue/Indigo Accent
const Color kLightBackground = Color(0xFFF5F6FA); // Scaffold Background
const Color kTextDark = Color(0xFF1E273A); // Dark text

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: The colors defined here will only be used for the CircleAvatar background and icon,
    // keeping the original accent colors for visual distinction.
    final List<Map<String, dynamic>> steps = [
      {
        "icon": Icons.account_balance_wallet_rounded,
        "title": "Budget Planning",
        "desc":
            "Learn how to record expenses, categorize spending, and manage budgets effectively.",
        "color": const Color(0xFF5B8DEE),
      },
      {
        "icon": Icons.flag_rounded,
        "title": "Goal Setting",
        "desc":
            "Understand how to set savings goals and track progress step-by-step.",
        "color": const Color(0xFF47CACC),
      },
      {
        "icon": Icons.dashboard_rounded,
        "title": "Dashboard",
        "desc":
            "Get an overview of your financial health and learn to interpret charts.",
        "color": const Color(0xFFF4C542),
      },
      {
        "icon": Icons.menu_book_rounded,
        "title": "Financial Education",
        "desc":
            "Discover articles and videos that help grow your financial literacy.",
        "color": const Color(0xFF52C27B),
      },
    
    ];

    return Scaffold(
      backgroundColor: kLightBackground, // Use standard light background
      appBar: AppBar(
        backgroundColor: Colors.white, // Clean, solid white header
        surfaceTintColor: Colors.white, // Ensure white on modern themes
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark), // Modern back arrow and dark text color
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "App Tutorial",
          style: TextStyle(
            color: kTextDark, // Use standard dark text color
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final item = steps[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 15), // Reduced padding slightly
              child: GestureDetector(
                onTap: () {
                  // 🔵 Navigation Logic
                  Widget? nextPage;
                  if (item["title"] == "Budget Planning") {
                    nextPage = const BudgetPlanningTutorial();
                  } else if (item["title"] == "Goal Setting") {
                    nextPage = const GoalSettingTutorial();
                  } else if (item["title"] == "Dashboard") {
                    nextPage = const DashboardTutorial();
                  } else if (item["title"] == "Financial Education") {
                    nextPage = const FinancialTutorial();
                  }
                  if (nextPage != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => nextPage!,
                      ),
                    );
                  }
                },
                child: _buildTutorialCard(
                  icon: item["icon"],
                  color: item["color"],
                  title: item["title"],
                  desc: item["desc"],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTutorialCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Rounded corners like other screens
        boxShadow: [
          // Modern, subtle shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
        children: [
          // Icon and colored background
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.18),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          // Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: kTextDark, // Consistent dark text
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: kTextDark.withOpacity(0.7), // Subdued text
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Arrow indicator
          const Icon(
            Icons.arrow_forward_ios_rounded, 
            size: 16, 
            color: Colors.black38
          ), 
        ],
      ),
    );
  }
}