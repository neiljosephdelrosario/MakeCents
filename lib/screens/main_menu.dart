import 'package:flutter/material.dart';
// IMPORTANT: Add the Fluent UI package import for the modern icon style
import 'package:fluentui_system_icons/fluentui_system_icons.dart'; 
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'dashboard_screen.dart';
import 'financial_educ_screen.dart';
import 'profile_screen.dart';
import 'tutorial_screen.dart';

// --- Global Menu Data Structure for cleaner code ---
class MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

final List<MenuItem> menuItems = [
  MenuItem(
    title: "Budget Planning",
    subtitle: "", // Removed subtitle
    icon: Icons.account_balance_wallet_rounded,
    color: const Color(0xFF5B8DEE), // Blue (Accent)
    screen: const BudgetScreen(),
  ),
  MenuItem(
    title: "Goal Setting",
    subtitle: "", // Removed subtitle
    icon: Icons.flag_rounded,
    color: const Color(0xFF47CACC), // Teal
    screen: const GoalsScreen(),
  ),
  MenuItem(
    title: "Dashboard",
    subtitle: "", // Removed subtitle
    icon: Icons.dashboard_rounded,
    color: const Color(0xFFF4C542), // Yellow/Gold
    screen: const DashboardScreen(),
  ),
  MenuItem(
    title: "Financial Education",
    subtitle: "", // Removed subtitle
    icon: Icons.menu_book_rounded,
    color: const Color(0xFF52C27B), // Green
    screen: const FinancialEducScreen(),
  ),
];

// ------------------------------------------
// MAIN MENU WIDGET (Stateful for animations)
// ------------------------------------------

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Tutorial Dialog (Preserved original functionality)
  void _showTutorialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Need a Tutorial?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This section will guide you through the features of the app and how to use them effectively.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorialScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Start Tutorial",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color modernBackground = Color(0xFFF9F9FB); 

    return Scaffold(
      backgroundColor: modernBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header (Logo and Profile Icon) ---
              Padding(
                padding: const EdgeInsets.only(
                    left: 25, right: 25, top: 20, bottom: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side: Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 40,
                      ),
                    ),
                    // Right side: Profile Icon Button
                    InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                      },
                      // MODIFIED: Replaced Material Icon with Fluent UI Icon
                      child: const Icon(
  FluentIcons.person_24_filled, // The IconData
  color: Color.fromARGB(255, 96, 91, 238), // Accent Color
  size: 32,
),
                    ),
                  ],
                ),
              ),

              // --- Title/Subtitle Area ---
              const Padding(
                padding: EdgeInsets.fromLTRB(25, 10, 25, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MakeCents",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Choose what to explore next",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // --- Responsive Grid with Staggered Animation ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final interval = Interval(
                      (index / menuItems.length) * 0.8,
                      1.0,
                      curve: Curves.easeOutCubic,
                    );

                    final animation = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(
                      parent: _controller,
                      curve: interval,
                    ));

                    return MenuCard(
                      item: item,
                      animation: animation,
                    );
                  },
                ),
              ),

              const SizedBox(height: 60),

              // --- Tutorial Button (Unchanged functionality as requested) ---
              Center(
                child: TextButton.icon(
                  onPressed: () => _showTutorialDialog(context),
                  icon: const Icon(Icons.help_outline_rounded,
                      color: Color(0xFF5B8DEE)),
                  label: const Text(
                    "Need a Tutorial?",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF5B8DEE),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------
// CUSTOM ANIMATED & RESPONSIVE MENU CARD
// ------------------------------------------
class MenuCard extends StatefulWidget {
  final MenuItem item;
  final Animation<double> animation;

  const MenuCard({
    super.key,
    required this.item,
    required this.animation,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    _navigateToScreen();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  void _navigateToScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => widget.item.screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: widget.animation,
          curve: Curves.easeOutSine,
        )),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = constraints.maxWidth;
                final double scale = (cardWidth / 160).clamp(0.85, 1.0);

                return Container(
                  padding: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: widget.item.color.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Circle
                      Container(
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.item.color.withOpacity(0.15),
                        ),
                        child: Icon(
                          widget.item.icon,
                          color: widget.item.color,
                          size: 32 * scale,
                        ),
                      ),
                      SizedBox(height: 15 * scale),
                      // Title
                      Text(
                        widget.item.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16 * scale,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      // MODIFIED: Conditionally display subtitle and its spacing
                      if (widget.item.subtitle.isNotEmpty) ...[
                        SizedBox(height: 5 * scale),
                        // Subtitle
                        Flexible(
                          child: Text(
                            widget.item.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: Colors.black54,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}