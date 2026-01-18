// lib/screens/edit_goal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:fluentui_system_icons/fluentui_system_icons.dart'; // For modern icons
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal_model.dart';
import '../hive_boxes.dart';

// --- Theme Colors for Consistency (Copied from other components) ---
const Color primaryAccent = Color(0xFF4C5BF0); 
const Color kLightBackground = Color(0xFFF0F2F5); // Light gray background for contrast
const Color kTextDark = Colors.black87; 
const Color kSuccessColor = Color(0xFF4CAF50); // Green for Success
const Color kExpenseColor = Color(0xFFD32F2F); // Red for Danger/Delete

class EditGoalScreen extends StatefulWidget {
  final GoalModel goal;
  final Function(GoalModel) onUpdate;
  final VoidCallback onDelete;

  const EditGoalScreen({
    super.key,
    required this.goal,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late TextEditingController nameController;
  late TextEditingController targetAmountController;
  // NOTE: savedAmountController has been removed as per user request.

  bool _isSaving = false;
  bool _isDeleting = false;
  
  // Currency formatter for display purposes
  final currencyFormatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');


  final Map<String, IconData> _fluentIconMap = const {
    'home': FluentIcons.home_24_regular,
    'cart': FluentIcons.cart_24_regular,
    'heart': FluentIcons.heart_24_regular,
    'airplane': FluentIcons.airplane_24_regular,
    'book': FluentIcons.book_24_regular,
    'briefcase': FluentIcons.briefcase_24_regular,
    'wallet': FluentIcons.wallet_24_regular,
    'calendar': FluentIcons.calendar_24_regular,
    'trophy': FluentIcons.trophy_24_regular,
    'gift': FluentIcons.gift_24_regular,
    'building': FluentIcons.building_24_regular,
    'beach': FluentIcons.beach_24_regular,
    'music': FluentIcons.music_note_2_24_regular,
    'game': FluentIcons.games_24_regular,
    'device': FluentIcons.device_meeting_room_24_regular,
    'camera': FluentIcons.camera_24_regular,
  };


  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.goal.name);
    // Use toStringAsFixed(2) for precise editing of currency fields
    targetAmountController =
        TextEditingController(text: widget.goal.targetAmount.toStringAsFixed(2));
    // NOTE: savedAmountController initialization removed.
  }

  @override
  void dispose() {
    nameController.dispose();
    targetAmountController.dispose();
    // NOTE: savedAmountController disposal removed.
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
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
    );
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

  void _saveGoal() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();

    final name = nameController.text.trim();
    final target = double.tryParse(targetAmountController.text) ?? 0.0;
    final saved = widget.goal.savedAmount; // Use the current model value

    if (name.isEmpty) {
      _showError('Goal name cannot be empty.');
      return;
    }
    if (target <= 0) {
      _showError('Target amount must be greater than zero.');
      return;
    }
    // New validation check: ensure existing saved amount doesn't exceed the new target
    if (saved > target) {
      _showError('The current saved amount (${currencyFormatter.format(saved)}) exceeds the new target amount.');
      return;
    }

    setState(() => _isSaving = true);

    await Future.delayed(const Duration(milliseconds: 400)); // Simulate save delay

    final updatedGoal = GoalModel(
      id: widget.goal.id,
      name: name,
      targetAmount: target,
      savedAmount: saved, // Use the original saved amount (unedited)
      // Keeping other properties intact
      iconName: widget.goal.iconName,
      startDate: widget.goal.startDate,
      endDate: widget.goal.endDate,
    );

    widget.onUpdate(updatedGoal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Goal "${name}" updated successfully!'),
        backgroundColor: primaryAccent,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  Future<void> _refundGoalSavingsToBudget(double refundAmount) async {
    if (refundAmount <= 0) return;

    final settingsBox = Hive.box('settings');
    final savedAllocRaw = settingsBox.get('budgetAllocations');
    Map<String, dynamic> allocs =
        savedAllocRaw is Map ? Map<String, dynamic>.from(savedAllocRaw) : {};

    final currentGoalsVal = (allocs['Goals'] ?? 0);
    double currentGoals =
        (currentGoalsVal is num) ? currentGoalsVal.toDouble() : 0.0;

    allocs['Goals'] = currentGoals + refundAmount;
    await settingsBox.put('budgetAllocations', allocs);
  }

  Future<double> _deleteRelatedGoalTransactions(String goalName) async {
    final txBox = HiveBoxes.getTransactions();
    final relatedTx = txBox.values
        .where((tx) =>
            tx.category == 'Goals' && tx.title == 'Saved to $goalName')
        .toList();

    double total = 0.0;
    for (var tx in relatedTx) {
      total += (tx.amount as num).toDouble();
      await tx.delete();
    }
    return total;
  }

  void _confirmDelete() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal Permanently',
            style: TextStyle(color: kExpenseColor, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this goal? Any previously saved amount will be returned to your Goals budget category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kExpenseColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isDeleting ? null : () async {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx); // Close confirmation dialog
              
              if (mounted) setState(() => _isDeleting = true);
              await Future.delayed(const Duration(milliseconds: 300)); // Simulating deletion
              
              // 1) Calculate total transactions related to this goal
              final txTotal =
                  await _deleteRelatedGoalTransactions(widget.goal.name);

              // 2) Get goal's original saved amount
              final goalSavedAmount = widget.goal.savedAmount;

              // 3) Refund only unaccounted amount
              final refundAmount = goalSavedAmount - txTotal;
              
              if (refundAmount > 0) {
                await _refundGoalSavingsToBudget(refundAmount);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${currencyFormatter.format(refundAmount)} has been refunded to your Goals budget.'),
                    backgroundColor: kExpenseColor,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }

              // 4) Call the delete callback to remove the goal itself
              widget.onDelete();

              if (mounted) setState(() => _isDeleting = false);
              
              // Close the edit sheet
              Navigator.pop(context);
            },
            child: _isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                  )
                : const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Recalculate progress on every build/state change
    final target = double.tryParse(targetAmountController.text) ?? 1;
    final saved = widget.goal.savedAmount; // Get saved amount directly from the model
    final progress = saved / target;
    final progressClamped = progress.clamp(0.0, 1.0);
    final progressColor = progressClamped >= 1.0 ? kSuccessColor : primaryAccent;

    final iconData = widget.goal.iconName != null &&
            _fluentIconMap.containsKey(widget.goal.iconName!)
        ? _fluentIconMap[widget.goal.iconName!]!
        : FluentIcons.wallet_24_regular;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Title and Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(iconData, size: 28, color: primaryAccent),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Goal',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kTextDark),
                    ),
                  ],
                ),
                // Delete button
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(FluentIcons.delete_24_regular, color: kExpenseColor),
                  tooltip: 'Delete Goal',
                )
              ],
            ),
            const Divider(height: 20, thickness: 1),
            const SizedBox(height: 16),

            // Goal Name
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration(
                label: 'Goal Name',
                icon: FluentIcons.text_field_24_regular,
              ),
            ),
            const SizedBox(height: 16),

            // Target Amount
            TextField(
              controller: targetAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: _buildInputDecoration(
                label: 'Target Amount',
                icon: FluentIcons.target_24_regular,
                isAmount: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            
            // Current Saved Amount (Read-Only Display)
           
            const SizedBox(height: 24),

            // Progress Section
            const Text(
              'Goal Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressClamped,
                minHeight: 12,
                backgroundColor: kLightBackground,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              // Progress text aligned to the right
              '${(progressClamped * 100).toStringAsFixed(1)}% complete | ${widget.goal.endDate != null ? "Due: ${DateFormat.yMd().format(widget.goal.endDate!)}" : "No deadline set"}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Save Button (Full Width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving || _isDeleting ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
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
                        'Save Changes',
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