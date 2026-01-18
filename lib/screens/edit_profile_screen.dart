import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Updated Color Theme to Match the Provided Image ---
const Color primaryColor = Color(0xFF5E54FF); // Vibrant Purple-Blue from the header
const Color secondaryColor = Color(0xFF8A84FF); // Slightly lighter for avatar background
const Color accentColor = Color(0xFFFF7043); // Kept for consistency if needed, but not used in this version
const Color backgroundColor = Colors.white; // Pure white background from the image

class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user.displayName ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Save Changes Logic (Same as before) ---
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if any field has actually changed
    bool nameChanged = _nameController.text != widget.user.displayName;
    bool emailChanged = _emailController.text != widget.user.email;
    bool passwordChanged = _passwordController.text.isNotEmpty;

    if (!nameChanged && !emailChanged && !passwordChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No changes to save.")),
        );
        return;
    }

    setState(() => _saving = true);

    try {
      if (nameChanged) {
        await widget.user.updateDisplayName(_nameController.text);
      }
      if (emailChanged) {
        await widget.user.updateEmail(_emailController.text);
      }
      if (passwordChanged) {
        await widget.user.updatePassword(_passwordController.text);
      }

      await widget.user.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  // --- Widget Build (Modernized UI with Image Theme) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Avatar Section (Simple, non-editable placeholder)
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: secondaryColor,
                  // Use the user's initial for the profile avatar
                  child: Text(
                    widget.user.displayName?.isNotEmpty == true
                        ? widget.user.displayName![0].toUpperCase()
                        : widget.user.email?[0].toUpperCase() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 50),

              // 2. Profile Details Card/Container
              // Using a simple Column structure as the background is white
              Column(
                children: [
                    // Display Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: "Display Name",
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter your name" : null,
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains("@")
                          ? "Enter a valid email"
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // New Password Field
                    _buildTextField(
                      controller: _passwordController,
                      label: "New Password (optional)",
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                ],
              ),

              const SizedBox(height: 50),

              // 3. Save Button
              ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for modern TextFormField style
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: const Color(0xFFF7F7F7), // A very light gray to differentiate
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, // Hide default border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
      validator: validator,
    );
  }
}