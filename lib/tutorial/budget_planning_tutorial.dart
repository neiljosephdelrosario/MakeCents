import 'package:flutter/material.dart';

// --- Theme Colors for Modern Look (Matching Calendar/TutorialScreen) ---
const Color kPrimaryColor = Color(0xFF4C5BF0); // Modern Blue/Indigo Accent
const Color kLightBackground = Color(0xFFF5F6FA); // Scaffold Background
const Color kTextDark = Color(0xFF1E273A); // Dark text

class BudgetPlanningTutorial extends StatefulWidget {
  const BudgetPlanningTutorial({super.key});

  @override
  State<BudgetPlanningTutorial> createState() => _BudgetPlanningTutorialState();
}

class _BudgetPlanningTutorialState extends State<BudgetPlanningTutorial> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  // The 5 image paths for the tutorial steps
  final List<String> images = [
    'assets/budgetplan/1budget.png',
    'assets/budgetplan/2budget.png',
    'assets/budgetplan/3budget.png',
    'assets/budgetplan/4budget.png',
    'assets/budgetplan/5budget.png',
  ];
  
  // Titles for each step (Still defined but now UNUSED, can be removed entirely if desired)
  final List<String> titles = [
    "Set Your Income",
    "Define Categories",
    "Allocate Funds",
    "Record Transactions",
    "Review and Adjust",
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper widget for dot indicators 
  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: currentPage == index ? 24 : 8, // Wider if active
      decoration: BoxDecoration(
        color: currentPage == index ? kPrimaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLastPage = currentPage == images.length - 1;

    return Scaffold(
      backgroundColor: kLightBackground, // Use consistent light background
      
      appBar: AppBar(
        // Modern AppBar styling
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, 
        elevation: 1, // Subtle elevation
        centerTitle: true,
        title: const Text(
          "Budget Planning Tutorial",
          style: TextStyle(
            color: kTextDark, // Use consistent dark text
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark), // Modern back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Column(
        children: [
          
          // 📄 PageView (Image Slideshow)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => currentPage = index);
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    children: [
                      // Removed the Step Title Text widget here:
                      /*
                      Text(
                        titles[index], 
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      */

                      // Image Container (Modern Card Style)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16), // Consistent rounding
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              images[index],
                              fit: BoxFit.contain, // Use contain to ensure the full image is seen
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Navigation Controls Footer
          Container(
            color: Colors.white, // White footer background
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                
                // 🔵 Indicators
                Row(
                  children: List.generate(
                    images.length,
                    (index) => _buildDotIndicator(index),
                  ),
                ),
                
                // ▶️ NEXT/FINISH Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLastPage) {
                        Navigator.pop(context); // Finish the tutorial
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor, // Use consistent primary color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                    ),
                    child: Text(
                      isLastPage ? "FINISH" : "NEXT",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}