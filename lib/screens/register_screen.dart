import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main_menu.dart';

// --- Define the primary logo/theme color for consistency ---
const Color kPrimaryColor = Color(0xFF4C5DFF); // Deep Blue/Purple
const Color kLightBackgroundColor = Color(0xFFF4F6FF); // Light background for text fields

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedGender = "I prefer not to say";
  bool _loading = false;
  bool _obscurePassword = true;
  bool _agreeTerms = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      _showError("Please agree to the Terms and Conditions.");
      return;
    }

    setState(() => _loading = true);

    try {
      final fullName = _nameController.text.trim();

      // 1. Create user with Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception("Registration failed");
      
      // ✅ MODIFICATION: Set the display name on the Firebase User object
      await user.updateDisplayName(fullName);

      // 2. Save user info to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': fullName, // Use the trimmed full name
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenu()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Registration error");
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient background (Thematic color)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // Use a lighter shade of the primary color for a subtle gradient
                colors: [Colors.white, kPrimaryColor.withOpacity(0.2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main content
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Image.asset(
                        'assets/logo.png',
                        height: 90,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.monetization_on,
                          color: kPrimaryColor, // Thematic fallback icon
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        "Welcome to Make Cents!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor, // Thematic text color
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Create your new account",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person_outline, color: kPrimaryColor), // Thematic icon color
                          filled: true,
                          fillColor: kLightBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder( // Thematic focused border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kPrimaryColor, width: 2),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Enter your name" : null,
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: "Gender",
                          prefixIcon: Icon(Icons.wc_outlined, color: kPrimaryColor), // Thematic icon color
                          filled: true,
                          fillColor: kLightBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder( // Thematic focused border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kPrimaryColor, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "Male", child: Text("Male")),
                          DropdownMenuItem(value: "Female", child: Text("Female")),
                          DropdownMenuItem(value: "I prefer not to say", child: Text("I prefer not to say")),
                        ],
                        onChanged: (val) => setState(() => _selectedGender = val ?? _selectedGender),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Username or Email",
                          prefixIcon: Icon(Icons.email_outlined, color: kPrimaryColor), // Thematic icon color
                          filled: true,
                          fillColor: kLightBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder( // Thematic focused border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kPrimaryColor, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            v == null || !v.contains("@") ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock_outline, color: kPrimaryColor), // Thematic icon color
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kPrimaryColor, // Thematic icon color
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: kLightBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder( // Thematic focused border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kPrimaryColor, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            v != null && v.length >= 6
                                ? null
                                : "Password must be at least 6 characters",
                      ),
                      const SizedBox(height: 16),

                      // Terms and Conditions
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            activeColor: kPrimaryColor, // Thematic checkbox color
                            onChanged: (val) {
                              setState(() {
                                _agreeTerms = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'By creating an account you agree to our ',
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: 'Term and Conditions',
                                    style: TextStyle(
                                      color: kPrimaryColor, // Thematic link color
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Register Button
                      _loading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor, // Thematic button color
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _register,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      const SizedBox(height: 25),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Have an account? ",
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                color: kPrimaryColor, // Thematic link color
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}