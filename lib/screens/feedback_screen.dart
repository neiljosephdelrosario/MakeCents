import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Modern Theme Colors for Consistency ---
const Color kPrimaryColor = Color(0xFF4C5BF0); // Modern Blue Accent
const Color kLightBackground = Color(0xFFF4F6FA); // Light Gray Background
const Color kTextDark = Color(0xFF1E273A); // Dark text

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSubmitting = false;
  // New state to manage post-submission UI: null, 'success', or 'error'
  String? _submissionStatus; 

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final user = _auth.currentUser;
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      _showSnackbar('Please enter your feedback to proceed.', Colors.orange.shade800);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firestore.collection('feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'userName': user?.displayName ?? 'Anonymous User',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      setState(() {
        _isSubmitting = false;
        _submissionStatus = 'success';
      });

    } catch (e) {
      _showSnackbar('Error submitting feedback. Please try again.', Colors.red.shade800);
      setState(() {
        _isSubmitting = false;
        _submissionStatus = 'error';
      });
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // --- WIDGETS FOR MODERN UI/ANIMATION ---
  
  // Custom Header (Back button and Animated Logo) - Stays in the Stack
  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // Animated Logo
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/logo.png', // Logo path
                height: 40, 
                // Using a light filter to ensure visibility against kLightBackground if needed
                // color: kTextDark, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm(bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'We’d love to hear your thoughts!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Help us improve your experience by sharing your ideas, suggestions, or issues.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: kTextDark.withOpacity(0.6),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // Text Field (Modern Look)
        TextField(
          controller: _messageController,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: 'Type your feedback here...',
            hintStyle: TextStyle(color: kTextDark.withOpacity(0.4)),
            fillColor: kLightBackground, // Lighter background for field
            filled: true,
            contentPadding: const EdgeInsets.all(20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none, // Remove border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.5), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Submit Button (Animated)
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            disabledBackgroundColor: kPrimaryColor.withOpacity(0.5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: kPrimaryColor.withOpacity(0.4),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
            },
            child: _isSubmitting
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Feedback',
                    key: ValueKey('submit'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Icon Animation
        SizedBox(
          height: 100,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: Colors.green.shade500,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Thank You!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your feedback has been successfully submitted. We appreciate your input!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: kTextDark.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 40),
        // Action button to go back to the previous screen
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: BorderSide(color: kPrimaryColor, width: 2),
          ),
          child: const Text('Go Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: kLightBackground, 
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 600 : double.infinity,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                // FIX: Increased top padding to ensure the content starts clearly below the fixed header/back button/logo.
                padding: const EdgeInsets.only(top: 100.0, bottom: 20), 
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  // AnimatedSwitcher handles the transition between form and success screen
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _submissionStatus == 'success' 
                        ? _buildSuccessScreen() 
                        : _buildFeedbackForm(isLargeScreen),
                    key: ValueKey<String>(_submissionStatus ?? 'form'),
                  ),
                ),
              ),
            ),
          ),
          
          // Custom Header (Back button and Logo) - Placed last in the Stack to ensure it's on top
          _buildHeader(),
        ],
      ),
    );
  }
}