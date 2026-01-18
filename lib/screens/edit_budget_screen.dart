import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

// Define a modern, clean color palette
const Color primaryColor = Color(0xFF4C5DFF); // Deep Blue/Purple for main actions
const Color accentColor = Color(0xFFFF4C5D); // Red Accent for delete/danger
const Color successColor = Color(0xFF4CAF50); // Green for savings/success
const Color secondaryBackgroundColor = Color(0xFFF0F2F5); // Light gray background
const Color cardColor = Colors.white; // Pure white for category cards
const Color kTextDark = Color(0xFF1E273A);

class EditBudgetScreen extends StatefulWidget {
  final Map<String, double> currentAllocations;
  // This is the EFFECTIVE monthly budget limit (Weekly * 4.33 or Monthly input)
  final double monthlyIncome; 

  const EditBudgetScreen({
    super.key,
    required this.currentAllocations,
    required this.monthlyIncome,
  });

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, TextEditingController> controllers;
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _newAmountController = TextEditingController();

  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // ADDED: State variables for income type and raw weekly income
  String _incomeType = 'monthly';
  double _rawWeeklyIncome = 0.0;
  
  final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  // MODIFIED: Load both income type and raw weekly income
  void _loadIncomeDetails() {
    final settingsBox = Hive.box('settings');
    _incomeType = settingsBox.get('incomeType', defaultValue: 'monthly') as String;
    // Explicitly fetch the raw weekly income for the weekly limit case
    _rawWeeklyIncome = (settingsBox.get('weeklyIncome', defaultValue: 0) as num).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _loadIncomeDetails(); // MODIFIED

    controllers = widget.currentAllocations.map(
      (key, value) => MapEntry(
        key,
        TextEditingController(text: value.toStringAsFixed(2)),
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_animationController);
  }

  @override
  void dispose() {
    for (var c in controllers.values) {
      c.dispose();
    }
    _newCategoryController.dispose();
    _newAmountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // This total is always the sum of the allocations entered in the text fields.
  double _calculateTotal() {
    return controllers.values.fold(
      0.0,
      (sum, controller) => sum + (double.tryParse(controller.text) ?? 0.0),
    );
  }

  // --- UX: Modern Add Category Bottom Sheet ---
  void _addCategory() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "➕ Add New Budget Category",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              const Divider(height: 20, thickness: 1),
              TextField(
                controller: _newCategoryController,
                decoration: _buildInputDecoration(
                  label: "Category Name",
                  icon: Icons.label_outline,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _newAmountController,
                decoration: _buildInputDecoration(
                  label: "Budget Amount",
                  icon: Icons.attach_money,
                  prefixText: "₱",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final name = _newCategoryController.text.trim();
                  final amount =
                      double.tryParse(_newAmountController.text.trim()) ?? 0.0;

                  if (name.isNotEmpty &&
                      !controllers.containsKey(name) &&
                      amount >= 0) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      controllers[name] = TextEditingController(
                          text: amount.toStringAsFixed(2));
                    });

                    _newCategoryController.clear();
                    _newAmountController.clear();
                    Navigator.pop(context);

                    // UX Feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Category '$name' added successfully! 🎉"),
                        backgroundColor: successColor,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Invalid name/amount or category exists.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    const Text("Add Category", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UX: Delete Confirmation and Animation ---
  void _deleteCategory(String key) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to remove the '$key' category?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                controllers.remove(key);
              });
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Save Logic with Loading State and Success Feedback ---
  Future<void> _saveAllocations() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    double total = _calculateTotal(); // Get the total allocations (weekly or monthly)
    
    // MODIFIED: Determine the correct limit to enforce against
    double allocationLimit = _incomeType == 'weekly' 
        ? _rawWeeklyIncome // Use raw weekly income (e.g., 1500)
        : widget.monthlyIncome; // Use effective monthly income

    if (total > allocationLimit) {
      HapticFeedback.heavyImpact();
      
      double overageAmount = total - allocationLimit;
      String overageUnit = _incomeType == 'weekly' 
          ? 'weekly' // The allocations are weekly, so the overage is weekly
          : 'monthly';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "🚨 OVER BUDGET: You must decrease your allocations by ${currencyFormatter.format(overageAmount.abs())} (${overageUnit} overage)."),
          backgroundColor: accentColor,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    // Simulate network delay for better UX feel
    await Future.delayed(const Duration(milliseconds: 500));

    final updated = controllers.map((key, controller) {
      return MapEntry(key, double.tryParse(controller.text) ?? 0.0);
    });

    setState(() => _isSaving = false);
    HapticFeedback.selectionClick();

    // UX Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Budget changes saved! ✅"),
        backgroundColor: successColor,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, updated);
  }

  // --- Custom Input Decoration for Modern Look ---
  InputDecoration _buildInputDecoration(
      {required String label, required IconData icon, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      filled: true,
      fillColor: secondaryBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    );
  }

  // --- Widget Build (Modernized UI without Icons) ---
  @override
  Widget build(BuildContext context) {
    double total = _calculateTotal();

    // MODIFIED CORE LOGIC: Determine the correct limit to enforce against
    double allocationLimit;
    String limitTitle;
    String overageUnit;

    if (_incomeType == 'weekly') {
      // Limit is the raw weekly input
      allocationLimit = _rawWeeklyIncome; 
      limitTitle = "Weekly Budget Limit";
      overageUnit = 'weekly';
    } else {
      // Limit is the effective monthly income
      allocationLimit = widget.monthlyIncome;
      limitTitle = "Monthly Budget Limit";
      overageUnit = 'monthly';
    }
    
    bool overBudget = total > allocationLimit;
    double displayLimit = allocationLimit;
    double displayTotal = total;

    double overageAmount = overBudget ? total - displayLimit : 0.0;
    
    return Scaffold(
      backgroundColor: secondaryBackgroundColor,
      appBar: AppBar(
        title: const Text("Edit Budget Allocation",
            style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
        backgroundColor: secondaryBackgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Summary Card
          _buildSummaryCard(total, overBudget, displayLimit, displayTotal, limitTitle),
          
          const SizedBox(height: 10),

          // 2. Category Header and Add Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Allocation Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildAddCategoryButton(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Category List (Icon-less and sleek)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: controllers.entries.map((entry) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(sizeFactor: animation, child: child);
                  },
                  child: _buildCategoryTile(entry.key, entry.value),
                );
              }).toList(),
            ),
          ),

          // 4. Sticky Bottom Save Section
          _buildBottomSaveBar(overBudget, overageAmount, overageUnit),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total, bool overBudget, double displayLimit, double displayTotal, String limitTitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$limitTitle:",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              currencyFormatter.format(displayLimit),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Allocated:",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  currencyFormatter.format(displayTotal),
                  style: TextStyle(
                    color: overBudget ? accentColor : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Progress is calculated against the relevant limit (allocationLimit)
            LinearProgressIndicator(
              value: displayTotal / displayLimit, 
              backgroundColor: Colors.white38,
              valueColor: AlwaysStoppedAnimation<Color>(
                  overBudget ? accentColor : successColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return GestureDetector(
      onTap: _addCategory,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 4),
              Text(
                "Add New",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String key, TextEditingController controller) {
    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  key,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    // Ensure only valid numbers are entered
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), 
                  ],
                  decoration: const InputDecoration(
                    hintText: "0.00",
                    prefixText: "₱",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: accentColor),
                onPressed: () => _deleteCategory(key),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBottomSaveBar(bool overBudget, double overageAmount, String overageUnit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overBudget)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "⚠️ Reduce allocation by ${currencyFormatter.format(overageAmount.abs())} (${overageUnit} overage)",
                style: const TextStyle(
                    color: accentColor, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: overBudget || _isSaving ? null : _saveAllocations,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: _isSaving
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}