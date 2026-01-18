import 'package:flutter/material.dart';

// --- Theme Colors for Modern Look (Consistent with other screens) ---
const Color kPrimaryColor = Color(0xFF4C5BF0); // Modern Blue/Indigo Accent
const Color kLightBackground = Color(0xFFF5F6FA); // Scaffold Background
const Color kTextDark = Color(0xFF1E273A); // Dark text

class FinancialTutorial extends StatelessWidget {
  const FinancialTutorial({super.key});

  final String image = 'assets/financial/1financial.png';
  final String title = "";

  // Helper widget for the Finish button
  Widget _buildFinishButton(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context), // Finish the tutorial
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor, // Use consistent primary color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30),
        ),
        child: const Text(
          "FINISH",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground, // Use consistent light background
      
      appBar: AppBar(
        // Modern AppBar styling
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, 
        elevation: 1, // Subtle elevation
        centerTitle: true,
        title: const Text(
          "Financial Education Tutorial",
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

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          children: [
            // Step Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

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
                    image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Navigation Controls Footer (Finish button)
            Align(
              alignment: Alignment.centerRight,
              child: _buildFinishButton(context),
            ),
          ],
        ),
      ),
    );
  }
}