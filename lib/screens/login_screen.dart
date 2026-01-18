import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main_menu.dart';
import 'register_screen.dart';

// --- Define the primary logo/theme color for consistency ---
const Color kPrimaryColor = Color(0xFF4C5DFF); // Deep Blue/Purple (consistent with primaryColor in other files)
const Color kLightBackgroundColor = Color(0xFFF4F6FF); // Light background for text fields

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenu()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email first.');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showError('Password reset email sent!');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Error sending reset email');
    }
  }

  Future<void> _googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenu()),
        );
      }
    } catch (e) {
      _showError('Google Sign-In failed. Try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _safeGoogleLogo() {
    return Image.asset(
      'assets/google.png',
      height: 24,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if google.png is missing
        return const Icon(Icons.account_circle, color: kPrimaryColor, size: 24);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient Background
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

          // Main Content Card
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
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor, // Thematic text color
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Sign in to continue",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Username or Email",
                          prefixIcon: Icon(Icons.email_outlined, color: kPrimaryColor), // Thematic icon color
                          filled: true,
                          fillColor: kLightBackgroundColor, // Thematic fill color
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

                      // Password field
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
                          fillColor: kLightBackgroundColor, // Thematic fill color
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
                            v == null || v.isEmpty ? "Enter your password" : null,
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            "Forgot your password?",
                            style: TextStyle(color: kPrimaryColor.withOpacity(0.7)), // Subtle thematic color
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Login Button
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
                              onPressed: _login,
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                      const SizedBox(height: 20),

                      // Google Sign-In Button (safe)
                      OutlinedButton.icon(
                        onPressed: _googleSignIn,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: kPrimaryColor), // Thematic border color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _safeGoogleLogo(),
                        label: const Text(
                          "Sign in with Google",
                          style: TextStyle(color: kPrimaryColor), // Thematic text color
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              "Sign Up",
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