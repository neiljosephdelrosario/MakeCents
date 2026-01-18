// lib/onboarding_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for keyboard input formatters
import 'package:hive/hive.dart';
import 'main_menu.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// Added SingleTickerProviderStateMixin for AnimationController
class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _pageOffset = 0.0; // NEW: Track page offset for custom animation

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();

  String _selectedGender = "I prefer not to say";
  String _incomeType = "monthly";

  late Box settingsBox;
  bool isFirstLaunch = true;
  bool _isIncomeValid = false; // State to track if income input is valid
  bool _showCongratsAnimation = false; // State for congratulations screen

  // Animation controller for the congratulatory screen elements
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern Color Palette (Based on logo/image_a91b66.png)
  static const Color primaryColor = Color(0xFF6E4DCB); // Purple Start
  static const Color accentColor = Color(0xFF4A90E2); // Blue End
  static const Color darkTextColor = Color(0xFF333333);
  static const Color lightGrey = Color(0xFFF7F9FC); // Soft background color

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box("settings");

    // Load flag
    isFirstLaunch = settingsBox.get("firstLaunch", defaultValue: true);
    
    // Animation setup (required by SingleTickerProviderStateMixin)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Scale for dramatic entry
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    // Opacity for fading in text
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));
    // Slide for the logo
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));

    // Add listener for real-time income validation
    _incomeController.addListener(_validateIncome);

    // NEW: Add listener for custom page transition animation
    _pageController.addListener(_onPageScroll);

    // Initial check
    _validateIncome();
  }

  void _onPageScroll() {
    // Only update offset if controller is attached and page is not null
    if (_pageController.hasClients) {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    }
  }

  @override
  void dispose() {
    _incomeController.removeListener(_validateIncome);
    _incomeController.dispose();
    _nameController.dispose();
    _pageController.removeListener(_onPageScroll); // REMOVE LISTENER
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Logic to check if the income field has a numerical value greater than zero
  void _validateIncome() {
    final income = double.tryParse(_incomeController.text.trim()) ?? 0;
    // Condition: Income must be greater than 0
    final isValid = income > 0.00;
    if (_isIncomeValid != isValid) {
      setState(() {
        _isIncomeValid = isValid;
      });
    }
  }

  void _saveAndFinish() {
    // Crucial check: button is disabled, but guard against programmatic click
    if (isFirstLaunch && !_isIncomeValid) {
      return; 
    }
    
    try {
      if (isFirstLaunch) {
        double income = double.tryParse(_incomeController.text.trim()) ?? 0;

        settingsBox.put("incomeType", _incomeType);
        if (_incomeType == "monthly") {
          settingsBox.put("monthlyIncome", income);
        } else {
          settingsBox.put("weeklyIncome", income);
        }

        // Mark onboarding as completed
        settingsBox.put("firstLaunch", false);
        
        // Trigger animation
        setState(() {
          _showCongratsAnimation = true;
          // Start the animation forward
          _animationController.forward();
        });

        // Navigate after the animation finishes (3.5 seconds total delay)
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MainMenu()));
          }
        });
        
      } else {
        // Not first launch, just navigate
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainMenu()));
      }
    } catch (e) {
      debugPrint("Error saving: $e");
    }
  }

  void _fabNext() {
    final pages = _buildPages();
    
    // Logic: Only move forward if not on the last page.
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), // Slightly longer animation
          curve: Curves.fastOutSlowIn); // Smoother curve for transition
    } else if (!isFirstLaunch) {
        // If it's the last page, but not the first launch (i.e., just navigating to main menu), finish.
        _saveAndFinish();
    }
  }

  // -------------------- PAGES --------------------
  List<Widget> _buildPages() {
    final pages = [
      _introPage(
          title: "Make Cents",
          subtitle: "Budget Smarter, Live Better – Anytime, Anywhere.",
          image: "assets/logo.png",
          page: 1), 
      _introFeaturesPage(), 
    ];

    if (isFirstLaunch) {
      pages.add(_personalInfoPage()); 
      pages.add(_incomeSelectionPage()); 
    }

    return pages;
  }

  // -------------------- Helpers --------------------
  Map<String, double> _units(BuildContext context) {
    final Size s = MediaQuery.of(context).size;
    final double w = s.width;
    final double h = s.height;
    final double bw = w / 100;
    final double bh = h / 100;
    return {"w": w, "h": h, "bw": bw, "bh": bh};
  }
  
  // Custom Input Decoration for a clean modern look
  InputDecoration _modernInputDecoration(Map<String, double> u, {required String hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: lightGrey,
      prefixIcon: prefix,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(u["bw"]! * 3),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(u["bw"]! * 3),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(u["bw"]! * 3),
          borderSide: BorderSide(color: primaryColor, width: 2.5)),
      contentPadding: EdgeInsets.symmetric(
          horizontal: u["bw"]! * 4,
          vertical: u["bh"]! * 1.8),
    );
  }

  Widget _labeledField(BuildContext context,
      {required String label, required Widget child}) {
    final u = _units(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: u["bw"]! * 4.0,
                fontWeight: FontWeight.w700,
                color: darkTextColor)),
        SizedBox(height: u["bh"]! * 1.0),
        child,
      ],
    );
  }

  // --------------------------- INTRO PAGE (Page 1) -----------------------------
  Widget _introPage(
      {required String title,
      required String subtitle,
      required String image,
      required int page}) {
    return Builder(builder: (context) {
      final u = _units(context);
      final double logoHeight = (u["h"]! * 0.18).clamp(60.0, u["h"]! * 0.25);

      return SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: u["bw"]! * 8, vertical: u["bh"]! * 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: u["bh"]! * 10),
                    // Logo with Hero transition
                    Hero(
                        tag: "logo",
                        child:
                            Image.asset(image, height: logoHeight, fit: BoxFit.contain)),
                    SizedBox(height: u["bh"]! * 4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: u["bw"]! * 8,
                        fontWeight: FontWeight.w900,
                        color: primaryColor, 
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: u["bh"]! * 1.5, bottom: u["bh"]! * 2),
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: u["bw"]! * 4.2,
                              color: darkTextColor.withOpacity(0.7),
                              height: 1.4),
                        ),
                      ),
                    SizedBox(height: u["bh"]! * 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // --------------------------- INTRO FEATURES PAGE (Page 2) -------------------------
  Widget _introFeaturesPage() {
    return Builder(builder: (context) {
      final u = _units(context);
      final double logoHeight = (u["h"]! * 0.13).clamp(44.0, u["h"]! * 0.18);

      final features = [
        {"icon": Icons.pie_chart_rounded, "title": "See Where Your Money Goes", "desc": "Visualize spending by category with beautiful charts."},
        {"icon": Icons.account_balance_wallet_rounded, "title": "Smarter Budgeting", "desc": "Set budgets and get helpful insights to stay on track."},
        {"icon": Icons.flag_rounded, "title": "Reach Your Goals!", "desc": "Success in your goals by tracking and monitoring it financially!"},
      ];

      return SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: u["bw"]! * 8, vertical: u["bh"]! * 3),
                child: Column(
                  children: [
                    SizedBox(height: u["bh"]! * 4),
                    Hero(
                        tag: "logo",
                        child: Image.asset("assets/logo.png",
                            height: logoHeight, fit: BoxFit.contain)),
                    SizedBox(height: u["bh"]! * 2),
                    Text(
                      "Make It Make Cents!",
                      style: TextStyle(
                          fontSize: u["bw"]! * 6.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor),
                    ),
                    SizedBox(height: u["bh"]! * 4),
                    Column(
                      children: features.map((f) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: u["bh"]! * 2.5),
                          child: Container(
                            padding: EdgeInsets.all(u["bw"]! * 4.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(u["bw"]! * 5),
                              boxShadow: [
                                BoxShadow(
                                    color: primaryColor.withOpacity(0.1), 
                                    blurRadius: u["bw"]! * 8,
                                    offset: Offset(0, u["bw"]! * 4))
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(u["bw"]! * 3),
                                  decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1), // Light accent background
                                      borderRadius: BorderRadius.circular(u["bw"]! * 3)),
                                  child: Icon(f["icon"] as IconData,
                                      color: primaryColor, // Accent icon color
                                      size: u["bw"]! * 5),
                                ),
                                SizedBox(width: u["bw"]! * 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f["title"] as String,
                                          style: TextStyle(
                                              fontSize: u["bw"]! * 4.2,
                                              fontWeight: FontWeight.w700,
                                              color: primaryColor)), // Accent title
                                      SizedBox(height: u["bh"]! * 0.6),
                                      Text(f["desc"] as String,
                                          style: TextStyle(
                                              fontSize: u["bw"]! * 3.6,
                                              color: darkTextColor.withOpacity(0.7))),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: u["bh"]! * 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }


  // --------------------------- PERSONAL INFO PAGE (Page 3) --------------------------
  Widget _personalInfoPage() {
    return Builder(builder: (context) {
      final u = _units(context);

      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: u["bw"]! * 8, vertical: u["bh"]! * 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: u["bh"]! * 4),
              Text("Tell Us About Yourself",
                  style: TextStyle(
                      fontSize: u["bw"]! * 7.0,
                      fontWeight: FontWeight.w700,
                      color: darkTextColor)),
              SizedBox(height: u["bh"]! * 1),
              Text("Just a few details to set up your profile.",
                  style: TextStyle(
                      fontSize: u["bw"]! * 3.8,
                      color: darkTextColor.withOpacity(0.7))),
              SizedBox(height: u["bh"]! * 4),
              _labeledField(
                context,
                label: "Your Name",
                child: TextField(
                  controller: _nameController,
                  decoration: _modernInputDecoration(u, hint: "Enter your full name"),
                ),
              ),
              SizedBox(height: u["bh"]! * 2.5),
              _labeledField(
                context,
                label: "Gender",
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  dropdownColor: Colors.white,
                  items: ["Male", "Female", "I prefer not to say"]
                      .map((g) => DropdownMenuItem(
                          value: g, child: Text(g, style: TextStyle(color: darkTextColor.withOpacity(0.8)))))
                      .toList(),
                  onChanged: (val) => setState(
                      () => _selectedGender = val ?? _selectedGender),
                  decoration: _modernInputDecoration(u, hint: "Select your gender")
                      .copyWith(contentPadding: EdgeInsets.symmetric(horizontal: u["bw"]! * 4, vertical: u["bh"]! * 1.8)),
                ),
              ),
              SizedBox(height: u["bh"]! * 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen())),
                  child: Text("Already have an account? Sign in",
                      style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: u["bw"]! * 3.8)),
                ),
              ),
              SizedBox(height: u["bh"]! * 4),
            ],
          ),
        ),
      );
    });
  }

  // --------------------------- INCOME PAGE (Page 4 - Final Screen) -------------------------------
  Widget _incomeSelectionPage() {
    return Builder(builder: (context) {
      final u = _units(context);

      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: u["bw"]! * 8, vertical: u["bh"]! * 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: u["bh"]! * 4),
              Text("Set Your Budget Base",
                  style: TextStyle(
                      fontSize: u["bw"]! * 7.0,
                      fontWeight: FontWeight.w700,
                      color: darkTextColor)),
              SizedBox(height: u["bh"]! * 1),
              Text("Enter your primary income. This is essential for smart budgeting.",
                  style: TextStyle(
                      fontSize: u["bw"]! * 3.8,
                      color: darkTextColor.withOpacity(0.7))),
              SizedBox(height: u["bh"]! * 4),
              
              // Monthly/Weekly Toggle 
              Container(
                padding: EdgeInsets.all(u["bw"]! * 1.2),
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(u["bw"]! * 4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: u["bw"]! * 2,
                        offset: Offset(0, u["bw"]! * 1))
                  ]
                ),
                child: Row(
                  children: [
                    _incomeToggle(context,
                        label: "Monthly",
                        value: "monthly",
                        u: u),
                    SizedBox(width: u["bw"]! * 2),
                    _incomeToggle(context,
                        label: "Weekly",
                        value: "weekly",
                        u: u),
                  ],
                ),
              ),
              SizedBox(height: u["bh"]! * 3),
              
              // Income Input Field (Validated)
              _labeledField(
                context,
                label: "Your ${_incomeType == 'monthly' ? 'Monthly' : 'Weekly'} Income (₱)",
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(u["bw"]! * 3),
                    boxShadow: [
                      BoxShadow(
                        // Add shadow feedback for valid state
                        color: _isIncomeValid ? primaryColor.withOpacity(0.15) : Colors.transparent,
                        blurRadius: 10,
                        offset: const Offset(0, 4)
                      )
                    ]
                  ),
                  child: TextField(
                    controller: _incomeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    // Only allow numeric input
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: TextStyle(fontSize: u["bw"]! * 5.0, fontWeight: FontWeight.w600, color: darkTextColor),
                    decoration: _modernInputDecoration(u, hint: "0.00")
                        .copyWith(
                          prefixText: "₱ ",
                          prefixStyle: TextStyle(
                              fontSize: u["bw"]! * 5.0,
                              fontWeight: FontWeight.bold,
                              // Prefix color changes based on validation state
                              color: _isIncomeValid ? primaryColor : Colors.grey.shade500),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: u["bw"]! * 3.6,
                            vertical: u["bh"]! * 2.0),
                        ),
                  ),
                ),
              ),
              SizedBox(height: u["bh"]! * 6),
              
              // Finish button (REQUIRED: Disabled until valid input)
              SizedBox(
                width: double.infinity,
                child: Material(
                  borderRadius: BorderRadius.circular(u["bw"]! * 4),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    // Logic: Only tap if income is valid (Strict validation)
                    onTap: _isIncomeValid ? _saveAndFinish : null,
                    borderRadius: BorderRadius.circular(u["bw"]! * 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: u["bh"]! * 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(u["bw"]! * 4),
                        // Gradient changes based on validation state
                        gradient: _isIncomeValid
                            ? LinearGradient(
                                colors: [primaryColor, accentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)
                            : LinearGradient(
                                colors: [Colors.grey.shade300, Colors.grey.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                      ),
                      child: Center(
                        child: Text("Done",
                            style: TextStyle(
                                fontSize: u["bw"]! * 4.6,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: u["bh"]! * 4),
            ],
          ),
        ),
      );
    });
  }

  // Income Toggle UI
  Widget _incomeToggle(BuildContext context,
      {required String label,
      required String value,
      required Map<String, double> u}) {
    final bool selected = _incomeType == value;
    final double radius = u["bw"]! * 3.5;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _incomeType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding:
              EdgeInsets.symmetric(vertical: u["bh"]! * 1.5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: primaryColor.withOpacity(0.15),
                        blurRadius: u["bw"]! * 4,
                        offset: Offset(0, u["bw"]! * 2))
                  ]
                : null,
            border: Border.all(
                color: selected ? primaryColor : Colors.transparent,
                width: selected ? 1.0 : 0),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: u["bw"]! * 4.0,
                  fontWeight: FontWeight.w700,
                  color: selected ? primaryColor : darkTextColor.withOpacity(0.6))),
        ),
      ),
    );
  }

  // --------------------------- CONGRATULATIONS SCREEN (Animated Welcome) --------------------------
  Widget _buildCongratulationsScreen() {
    final u = _units(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _showCongratsAnimation ? _opacityAnimation.value.clamp(0.0, 1.0) : 0.0,
          child: Container(
            color: Colors.white, // White background for the congratulatory screen
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo (Scaling up and sliding down)
                      Hero(
                          tag: "logo",
                          child: Image.asset("assets/logo.png",
                              height: u["bw"]! * 40, fit: BoxFit.contain)),
                      SizedBox(height: u["bh"]! * 4),
                      Text(
                        "Welcome to Make Cents!",
                        style: TextStyle(
                          fontSize: u["bw"]! * 7.5,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: u["bh"]! * 2),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: u["bw"]! * 12),
                        child: Text(
                          "Let's start making your money smarter.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: u["bw"]! * 4.5,
                            color: darkTextColor.withOpacity(0.8),
                            height: 1.4
                          ),
                        ),
                      ),
                      SizedBox(height: u["bh"]! * 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------- BOTTOM NAV / INDICATOR --------------------------
  Widget _buildBottomOverlay(BuildContext context, int count) {
    final u = _units(context);
    // Fixed height for the bottom navigation area
    final double overlayHeight = u["bh"]! * 15; 
    
    final bool isLastPage = _currentPage == count - 1;
    // Hide FAB on the final income input page for first launch
    final bool hideFab = isFirstLaunch && isLastPage; 
  
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: overlayHeight,
      // Simple container for the bottom navigation area
      child: Container(
        decoration: BoxDecoration(
          color: hideFab ? Colors.transparent : Colors.white,
          // The top border/line has been removed as requested.
        ),
        child: Stack(
          children: [
            // Page Indicator Dots
            Positioned(
              left: 0,
              right: 0,
              bottom: u["bh"]! * 5, // Position dots higher
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(count, (i) {
                    final selected = _currentPage == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: EdgeInsets.symmetric(horizontal: u["bw"]! * 1.2),
                      height: u["bh"]! * 1.2,
                      width: selected ? u["bw"]! * 8 : u["bw"]! * 2.8,
                      decoration: BoxDecoration(
                        // Dots use primary color for visibility
                        color: selected ? primaryColor : primaryColor.withOpacity(0.3), 
                        borderRadius: BorderRadius.circular(u["bw"]! * 10),
                      ),
                    );
                  }),
                ),
              ),
            ),
            
            // FAB 
            if (!hideFab)
              Positioned(
                right: u["bw"]! * 8,
                bottom: u["bh"]! * 4,
                child: Material(
                  elevation: u["bw"]! * 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(u["bw"]! * 4)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(u["bw"]! * 4),
                    onTap: _fabNext,
                    child: Container(
                      width: u["bw"]! * 14,
                      height: u["bw"]! * 14,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(u["bw"]! * 4),
                          // Gradient for the FAB itself (Catchy)
                          gradient: LinearGradient(
                              colors: [primaryColor, accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded, 
                        color: Colors.white, // White icon on gradient background
                        size: u["bw"]! * 6,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------- BUILD ---------------------------
  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    // Ensure the current page index is valid after pages rebuild
    if (_currentPage >= pages.length && pages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentPage = pages.length - 1);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              // *** Custom Page Transition Animation Logic ***
              // Calculate the difference from the current page offset
              double difference = i - _pageOffset;
              // Clamp to control the animation boundary
              double scale = 1.0;
              double opacity = 1.0;

              // Use lerpDouble for smooth interpolation
              if (difference.abs() <= 1.0) {
                // Scale from 0.95 (far) to 1.0 (center)
                scale = lerpDouble(0.95, 1.0, 1.0 - difference.abs())!;
                // Opacity from 0.5 (far) to 1.0 (center)
                opacity = lerpDouble(0.5, 1.0, 1.0 - difference.abs())!;
              } else {
                // Pages far away stay at the small scale and low opacity
                scale = 0.95;
                opacity = 0.5;
              }
              
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: pages[i],
                ),
              );
            },
          ),
          // We build the bottom overlay only if there are pages to show
          if (pages.isNotEmpty)
            _buildBottomOverlay(context, pages.length), 
            
          // Congratulations Screen Overlay (on top of everything)
          if (_showCongratsAnimation)
            _buildCongratulationsScreen(),
        ],
      ),
    );
  }
}