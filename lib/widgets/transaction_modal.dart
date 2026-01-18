import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

// --- Theme Colors for Consistency (Matching Budget/Dashboard Screens) ---
const Color primaryAccent = Color(0xFF4C5BF0); 
const Color kLightBackground = Color(0xFFF0F2F5); // Light gray background for contrast
const Color kTextDark = Colors.black87; 
const Color kExpenseColor = Color(0xFFD32F2F); // Red for visual consistency

class TransactionModal extends StatefulWidget {
  // isIncome is now always false for this modal, but kept in signature
  // to maintain compatibility with the onAdd callback.
  final void Function(String title, String category, double amount, bool isIncome) onAdd;
  final List<String> categories;

  const TransactionModal({
    super.key,
    required this.onAdd,
    required this.categories,
  });

  @override
  State<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends State<TransactionModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  
  // Locked to false as per user request (Expense-only modal)
  final bool _isIncome = false; 

  // UX Feedback variables
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to the first category if available
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Helper method for modern Input Decoration
  InputDecoration _buildInputDecoration({
    required String label, 
    required IconData icon, 
    bool isAmount = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryAccent.withOpacity(0.7)),
      prefixText: isAmount ? "₱ " : null,
      prefixStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: kTextDark.withOpacity(0.7),
      ),
      filled: true,
      fillColor: kLightBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
    );
  }

  void _submitData() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    // Category check is always required for an expense
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showError("Please select a budget category.");
      return;
    }

    // Input validation
    if (title.isEmpty || amount <= 0) {
      _showError("Please enter a valid title and amount.");
      return;
    }

    // Set loading state for UX feedback
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    // Simulate save delay for better UX feel
    await Future.delayed(const Duration(milliseconds: 400));

    // Always submit as an expense (isIncome: false)
    widget.onAdd(title, _selectedCategory!, amount, false);

    // UX Feedback on success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Expense added successfully!"),
        backgroundColor: primaryAccent, 
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚨 $message"),
        backgroundColor: kExpenseColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Action color is now always the primary accent for the expense action
    const Color actionColor = primaryAccent; 
    // Get keyboard inset dynamically
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        // Modern Bottom Sheet Styling
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Title and Close Button (Static "Record New Expense")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Record New Expense",
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w800, 
                    color: kTextDark
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.dismiss_24_regular, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            const SizedBox(height: 20), // Increased spacing after header

            // 1. Title Field (Static label for expense)
            TextField(
              controller: _titleController,
              decoration: _buildInputDecoration(
                label: "Title (e.g., Dinner, Rent)",
                icon: FluentIcons.text_field_24_regular,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // 2. Amount Field
            TextField(
              controller: _amountController,
              decoration: _buildInputDecoration(
                label: "Amount",
                icon: FluentIcons.money_24_regular,
                isAmount: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Allows only numbers and one decimal point for currency
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Category Field (Always visible and required)
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: widget.categories.isNotEmpty
                  ? (value) => setState(() => _selectedCategory = value)
                  : null,
              items: widget.categories.isNotEmpty
                  ? widget.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w500)),
                      );
                    }).toList()
                  : const [
                      DropdownMenuItem(
                        value: null,
                        child: Text("No categories available", style: TextStyle(color: Colors.red)),
                      ),
                    ],
              decoration: _buildInputDecoration( 
                label: "Category",
                icon: FluentIcons.tag_24_regular,
              ),
              icon: Icon(FluentIcons.chevron_down_24_regular, color: primaryAccent),
            ),
            const SizedBox(height: 24),

            // 4. Action Button (Static "Add Expense" button)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "Add Expense",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}