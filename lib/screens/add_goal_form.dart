// lib/screens/add_goal_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../models/goal_model.dart';

// --- Theme Colors for Consistency ---
const Color primaryAccent = Color(0xFF4C5BF0); 
const Color kLightBackground = Color(0xFFF0F2F5); // Light gray background for contrast
const Color kTextDark = Colors.black87; 
const Color kExpenseColor = Color(0xFFD32F2F); 

class AddGoalForm extends StatefulWidget {
  final VoidCallback onGoalAdded;
  const AddGoalForm({super.key, required this.onGoalAdded});

  @override
  State<AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends State<AddGoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final uuid = const Uuid();

  DateTime? startDate;
  DateTime? endDate;

  // UX Feedback variables
  bool _isLoading = false;

  /// SELECTED ICON NAME
  String selectedIconName = "wallet"; // Changed to use the map key

  /// SAMPLE FLUENT ICON SET (Keys match the icons)
  final Map<String, IconData> fluentIconMap = {
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

  Future<void> _pickStartDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'SELECT START DATE', // UX Improvement
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: startDate ?? DateTime.now(), // Ensure end date is after start date
      lastDate: DateTime(2100),
      helpText: 'SELECT GOAL DEADLINE', // UX Improvement
    );

    // Validate if the selected date is before the start date
    if (picked != null) {
      if (startDate != null && picked.isBefore(startDate!)) {
        _showError("Deadline cannot be before the start date.");
        return;
      }
      setState(() => endDate = picked);
    }
  }

  void _saveGoal() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) {
      _showError("Please fill in all required fields.");
      return;
    }

    final targetAmount = double.tryParse(_targetController.text.trim()) ?? 0.0;
    if (targetAmount <= 0) {
      _showError("Target amount must be greater than zero.");
      return;
    }
    if (endDate == null) {
       _showError("Please select a goal deadline.");
      return;
    }

    setState(() => _isLoading = true);
    
    // Default startDate to today if not picked
    final finalStartDate = startDate ?? DateTime.now();

    final goal = GoalModel(
      id: uuid.v4(),
      name: _nameController.text.trim(),
      targetAmount: targetAmount,
      savedAmount: 0.0,
      iconName: selectedIconName,
      startDate: finalStartDate,
      endDate: endDate!,
    );

    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 500)); 

    final box = Hive.box<GoalModel>('goals');
    await box.put(goal.id, goal);

    // Success Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Goal '${goal.name}' added successfully!"),
        backgroundColor: primaryAccent,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() => _isLoading = false);
    widget.onGoalAdded();
    Navigator.pop(context);
  }

  // Custom Button Widget for Date Pickers (Modern Look)
  Widget _buildDatePickerButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    final bool isSet = date != null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isSet ? primaryAccent : Colors.grey),
      label: Text(
        isSet ? DateFormat.yMd().format(date!) : label,
        style: TextStyle(
          fontWeight: isSet ? FontWeight.bold : FontWeight.normal,
          color: isSet ? kTextDark : Colors.grey.shade700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: BorderSide(
          color: isSet ? primaryAccent.withOpacity(0.5) : Colors.grey.shade300,
          width: 1.5,
        ),
        backgroundColor: isSet ? primaryAccent.withOpacity(0.05) : Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Modern Bottom Sheet UX
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Set a New Goal",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kTextDark),
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.dismiss_24_regular, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),
              const SizedBox(height: 16),

              // ICON PICKER SECTION
              const Text("Select Icon",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextDark)),
              const SizedBox(height: 12),

              SizedBox(
                height: 60, // Reduced height for a compact look
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: fluentIconMap.length,
                  itemBuilder: (context, i) {
                    final key = fluentIconMap.keys.elementAt(i);
                    final iconData = fluentIconMap[key]!;
                    final selected = key == selectedIconName;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => selectedIconName = key);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? primaryAccent.withOpacity(0.9)
                              : kLightBackground,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: selected ? primaryAccent : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          iconData,
                          size: 28,
                          color: selected ? Colors.white : kTextDark,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // FORM FIELDS
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration(
                        label: "Goal Name (e.g., New Car Fund)",
                        icon: FluentIcons.text_field_24_regular,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "Goal name is required"
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Target Amount
                    TextFormField(
                      controller: _targetController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: _buildInputDecoration(
                        label: "Target Amount",
                        icon: FluentIcons.money_24_regular,
                        isAmount: true,
                      ),
                      validator: (v) {
                        final amount = double.tryParse(v ?? '0');
                        if (amount == null || amount <= 0) {
                          return "Enter a valid amount";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerButton(
                            label: "Set Start Date",
                            date: startDate,
                            onPressed: _pickStartDate,
                            icon: FluentIcons.calendar_ltr_24_regular,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDatePickerButton(
                            label: "Set Deadline",
                            date: endDate,
                            onPressed: _pickEndDate,
                            icon: FluentIcons.calendar_checkmark_16_filled,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
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
                                "Create Goal",
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
            ],
          ),
        ),
      ),
    );
  }
}