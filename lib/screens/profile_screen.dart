import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:makecents_capstone/screens/feedback_screen.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart'; // Add for consistency with goals_screen
import 'login_screen.dart';
import 'register_screen.dart';
import 'edit_profile_screen.dart';
import 'calendar_screen.dart'; 

// --- Consistent Theme Colors (Copied from goals_screen.dart) ---
const Color primaryAccent = Color(0xFF4C5BF0); 
const Color kLightBackground = Colors.white; 
const Color kTextDark = Colors.black87; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get the initial letter for the avatar
  String _getUserInitial(User? user) {
    if (user == null) return '?';
    
    // Use displayName if available, otherwise use email
    String name = user.displayName ?? user.email ?? "";

    if (name.isNotEmpty) {
      // Get the first letter and capitalize it
      return name.trim().substring(0, 1).toUpperCase();
    }
    return '?';
  }

  // Enhanced Menu Tile (Matching the style of GoalsScreen list items)
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // Reduced vertical padding
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Increased radius
        child: Container(
          padding: const EdgeInsets.all(16), // Consistent padding
          decoration: BoxDecoration(
            color: kLightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100), // Subtle border
            boxShadow: [
              BoxShadow( // Accent-color subtle shadow
                color: primaryAccent.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with primary accent color
              Icon(icon, color: primaryAccent, size: 24), 
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16, // Slightly larger font
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600, // Slightly darker grey
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(FluentIcons.chevron_right_24_regular, color: Colors.grey), // Fluent Icon for consistency
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground, // Use consistent background
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final userInitial = _getUserInitial(user);
          final userName = user?.displayName ?? "No Name";
          final userEmail = user?.email ?? "No Email";
          
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 🔵 Top gradient header (with Back Button and User Initial)
                  Container(
                    width: double.infinity,
                    height: 250, // Increased height for better visual
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryAccent, primaryAccent.withOpacity(0.8)], // Use primaryAccent
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                            color: primaryAccent.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Stack(
                      children: [
                        // --- BACK BUTTON ---
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            icon: const Icon(FluentIcons.arrow_left_24_filled, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Back',
                          ),
                        ),
                        
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10), // Offset for back button
                              // --- PROFILE AVATAR with User Initial ---
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white.withOpacity(0.9), // Near-white contrast
                                child: Text(
                                  userInitial,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: primaryAccent, // Initial in primary color
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==========================
                  // 	SIGNED IN UI
                  // ==========================
                  if (user != null) ...[
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 20, // Slightly larger
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14, // Slightly larger
                      ),
                    ),
                    const SizedBox(height: 15),

                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: user),
                          ),
                        );
                        // Re-fetch or update state after returning from EditProfileScreen
                        setState(() {}); 
                      },
                      icon: const Icon(FluentIcons.edit_24_regular, size: 18, color: Colors.white), // Fluent Icon
                      label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent, // Use primaryAccent
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25), // Increased radius
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 25), // More space

                    // 📅 CALENDAR / ALL TIME RECORDS
                    _buildMenuTile(
                      icon: FluentIcons.calendar_24_regular, // Fluent Icon
                      title: "Calendar / All Time Records",
                      subtitle: "View your monthly financial summaries and trends", // Improved subtitle
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CalendarScreen()),
                        );
                      },
                    ),

                    // ❓ FEEDBACK
                    _buildMenuTile(
                      icon: FluentIcons.chat_help_24_regular, // Fluent Icon
                      title: "Feedback & Support", // Improved title
                      subtitle: "Contact us or view frequently asked questions", // Improved subtitle
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 30), // More space before sign out
                    TextButton(
                      onPressed: () async {
                        await _auth.signOut();
                      },
                      child: const Text(
                        "Sign Out",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold, // Make sign out prominent
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ]

                  // ==========================
                  // 	NOT SIGNED IN UI
                  // ==========================
                  else ...[
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign in to manage your profile and access full features.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // SIGN UP BUTTON
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        "Sign Up An Account",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // LOGIN LINK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already Have An Account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Sign In Here.",
                            style: TextStyle(
                              color: primaryAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    
                    // ❓ FEEDBACK (for non-signed in users)
                    _buildMenuTile(
                      icon: FluentIcons.chat_help_24_regular, // Fluent Icon
                      title: "Feedback & Support",
                      subtitle: "Contact us or view frequently asked questions",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}