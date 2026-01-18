import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:makecents_capstone/models/transaction_model.dart';
import '../services/gemini_service.dart';
import '../hive_boxes.dart';

class AiBudgetScreen extends StatefulWidget {
  const AiBudgetScreen({super.key});

  @override
  State<AiBudgetScreen> createState() => _AiBudgetScreenState();
}

class _AiBudgetScreenState extends State<AiBudgetScreen> {
  bool loading = false;
  String fullAiResponse = ""; // Stores the raw response for parsing
  String shortExplanation = "Tap 'Generate' to see your smart budget explanation."; // New: short explanation for the UI
  Map<String, double> suggestedAllocations = {}; // PESO amounts

  // Helper to format currency for the UI
  String _formatCurrency(double amount) {
    // Simple ₱ formatting for Philippines Peso
    return "₱${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Lighter background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "AI Smart Budgeting",
          style: TextStyle(
            color: Color(0xFF192A56), // Darker, professional color
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // INTRO CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 8,
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4A90E2), // Main Blue
                      Color(0xFF8BB5ED), // Lighter Blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "50/30/20 Budget Advisor",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Optimize your finances by aligning spending with your existing categories and the 50/30/20 rule.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // GENERATE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _generateAiBudget,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2ecc71), // A fresh green for action
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Generate Smart Budget",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 18),

            // AI EXPLANATION CARD (MODERN CHIP STYLE)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECF0F1), // Light neutral background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBDC3C7), width: 0.5),
              ),
              child: Text(
                shortExplanation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 18),

            // ALLOCATIONS & APPLY BUTTON
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: suggestedAllocations.isEmpty
                      ? Center(
                          child: Text(
                            loading ? "Analyzing transactions..." : "Tap the button above to generate a new budget.",
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "📊 Suggested Monthly Allocations",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF192A56),
                              ),
                            ),
                            const Divider(height: 20),
                            Expanded(
                              child: ListView(
                                children: suggestedAllocations.entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e.key,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          _formatCurrency(e.value),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A90E2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _applyAiBudget,
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                label: const Text(
                                  "Apply Suggested Budget",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // GENERATE + PARSE AI OUTPUT
  // --------------------------------------------------------------
  Future<void> _generateAiBudget() async {
    setState(() {
      loading = true;
      fullAiResponse = "";
      shortExplanation = "Generating budget and analyzing 50/30/20 split...";
      suggestedAllocations.clear();
    });

    final transactionsBox =
        Hive.box<TransactionModel>(HiveBoxes.transactionBox);
    final settingsBox = Hive.box(HiveBoxes.settingsBox);

    // Determine user's base budget
    final incomeType = settingsBox.get('incomeType', defaultValue: 'monthly');
    final savedMonthly = (settingsBox.get('monthlyIncome', defaultValue: 0) as num).toDouble();
    final savedWeekly = (settingsBox.get('weeklyIncome', defaultValue: 0) as num).toDouble();
    double baseBudget = incomeType == 'weekly' ? savedWeekly : savedMonthly;

    // ... [Base budget calculation logic remains the same]
    if (baseBudget == 0) {
      final fallbackIncome = transactionsBox.values
          .where((tx) => tx.isIncome && tx.date.month == DateTime.now().month && tx.date.year == DateTime.now().year)
          .fold(0.0, (s, tx) => s + tx.amount);
      if (fallbackIncome > 0) {
        baseBudget = fallbackIncome;
      } else {
        final fallbackExpenses = transactionsBox.values
            .where((tx) => !tx.isIncome)
            .fold(0.0, (s, tx) => s + tx.amount);
        baseBudget = fallbackExpenses > 0 ? fallbackExpenses : 0.0;
      }
    }
    
    // Collect categories the user already has in budget allocations or transactions
    final existingAllocMap = settingsBox.get('budgetAllocations');
    final Map<String, double> existingAllocations = existingAllocMap != null
        ? Map<String, double>.from((existingAllocMap as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
        : {};

    final Set<String> categories = {};
    if (existingAllocations.isNotEmpty) {
      categories.addAll(existingAllocations.keys);
    } else {
      for (var tx in transactionsBox.values) {
        if (!tx.isIncome) categories.add(tx.category);
      }
    }

    if (categories.isEmpty) {
      categories.add('Misc');
    }

    // Build category totals for prompt
    Map<String, double> categoryTotals = {};
    for (var tx in transactionsBox.values) {
      if (!tx.isIncome) {
        categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
      }
    }
    
    // MODIFIED PROMPT: Now requests an explanation block
    final categoriesText = categories.map((c) => "- $c").join("\n");
    final prompt = """
You are an expert financial assistant. The user wants a budget split that follows the 50/30/20 principle (50% Needs, 30% Wants, 20% Savings/Debt), but you MUST produce allocations mapped to the user's EXISTING categories only (do NOT create new categories or rename them).

Total Budget (to allocate): ₱${baseBudget.toStringAsFixed(2)}

User categories (allocate across these exactly):
$categoriesText

Category recent spend totals (helpful context):
${categoryTotals.entries.map((e) => "- ${e.key}: ₱${e.value.toStringAsFixed(2)}").join("\n")}

Output instructions (READ CAREFULLY):

1.  **FIRST BLOCK (EXPLANATION):** Provide a single paragraph of NO MORE THAN 50 words explaining how you applied the 50/30/20 rule to the user's specific categories. Start this explanation with the literal text: "EXPLANATION: ".
2.  **SECOND BLOCK (ALLOCATIONS):** Return only lines in one of the two formats (one category per line). Do NOT use any markdown or extra text around these lines.
    CategoryName: 25%
    CategoryName: ₱2500
- Do NOT include any other text, markdown, or extra commentary outside of the "EXPLANATION: " block and the allocation lines.
- Do NOT add or remove categories. Only output the categories listed above.
""";

    final gemini = GeminiService("AIzaSyASrRwcRPzqTPX2PPRC5ToJe0qBvUaD7N4"); // Use your key

    String response;
    try {
      response = await gemini.generateBudgetSuggestion(prompt);
    } catch (e) {
      response = "AI Error: $e";
    }

    // 1. EXTRACT EXPLANATION
    String parsedExplanation = _extractExplanation(response);
    
    // 2. CLEAN RESPONSE FOR ALLOCATION PARSING
    String cleanedResponse = _cleanResponseForParsing(response);

    // 3. PARSE ALLOCATIONS
    Map<String, double> parsed = _parseAllocations(cleanedResponse, baseBudget);

    // 4. Handle Fallback/Normalization
    if (parsed.isEmpty) {
      parsed = _fallbackProportionalAllocation(categories.toList(), categoryTotals, baseBudget);
      parsedExplanation = "AI failed to return usable data. A fallback proportional allocation based on past spending has been applied.";
    }
    
    // Ensure allocations sum exactly to baseBudget
    parsed = _normalizeToBudget(parsed, baseBudget);


    setState(() {
      loading = false;
      suggestedAllocations = parsed;
      // Set the appropriate response message
      shortExplanation = parsedExplanation.isNotEmpty
          ? parsedExplanation
          : "Budget generated successfully! Allocations are displayed below.";
    });
  }

  // --- NEW Helper Functions ---

  // Extracts the short explanation from the AI's full response
  String _extractExplanation(String response) {
    const startTag = "EXPLANATION:";
    if (response.contains(startTag)) {
      final startIndex = response.indexOf(startTag) + startTag.length;
      String explanation = response.substring(startIndex).trim();
      
      // The explanation should end before the first allocation line starts
      final firstAllocationLine = explanation.split('\n').firstWhere(
        (line) => line.contains(':') && (line.contains('%') || line.contains('₱')),
        orElse: () => explanation, // If no allocation found, use the whole thing
      );
      
      // If a line was found, cut the explanation at that point
      if (firstAllocationLine != explanation) {
        explanation = explanation.substring(0, explanation.indexOf(firstAllocationLine)).trim();
      }
      
      return explanation.replaceAll('\n', ' ').trim();
    }
    return ""; // Return empty string if not found
  }

  // Removes the explanation block and cleans up artifacts
  String _cleanResponseForParsing(String response) {
    const startTag = "EXPLANATION:";
    if (response.contains(startTag)) {
      final startIndex = response.indexOf(startTag);
      
      // Find where the explanation block ends (before the first allocation line)
      final explanationBlock = response.substring(startIndex);
      final allocationLineIndex = explanationBlock.split('\n').indexWhere(
        (line) => line.contains(':') && (line.contains('%') || line.contains('₱')),
      );

      if (allocationLineIndex != -1) {
          // Find the starting index of the allocation lines
          int allocationStart = startIndex;
          for (int i = 0; i < allocationLineIndex; i++) {
              allocationStart = explanationBlock.indexOf('\n', allocationStart + 1);
              if (allocationStart == -1) break;
          }
          
          // Use everything after the explanation block as the allocation text
          if (allocationStart != -1) {
              return response.substring(allocationStart).trim();
          }
      }
      // If we failed to find a clean cutoff, just remove the tag and its content crudely
      response = response.substring(response.indexOf(startTag) + startTag.length).trim();
    }
    
    // Clean up any remaining markdown/artifacts
    response = response
        .replaceAll("***", "")
        .replaceAll("**", "")
        .replaceAll("*", "")
        .replaceAll("_", "")
        .trim();
        
    return response;
  }
  
  // --------------------------------------------------------------
  // The rest of the helper functions (_parseAllocations, _fallbackProportionalAllocation, _normalizeToBudget, _roundAndFix, _applyAiBudget)
  // are the same as your original, functional code and are omitted here for brevity.
  // --------------------------------------------------------------
  
  // --------------------------------------------------------------
  // PARSER: percent → pesos | pesos → pesos
  // --------------------------------------------------------------
  Map<String, double> _parseAllocations(String text, double baseAmount) {
    final Map<String, double> out = {};

    final percentRegex =
        RegExp(r'^(.+?):\s*([0-9]+(?:\.[0-9]+)?)%\s*$', multiLine: true);
    final pesoRegex =
        RegExp(r'^(.+?):\s*₱?\s*([0-9]+(?:\.[0-9]+)?)\s*$', multiLine: true);

    for (var rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      var m1 = percentRegex.firstMatch(line);
      if (m1 != null) {
        final cat = m1.group(1)!.trim();
        final pct = double.tryParse(m1.group(2)!) ?? 0.0;
        out[cat] = (pct / 100.0) * baseAmount;
        continue;
      }

      var m2 = pesoRegex.firstMatch(line);
      if (m2 != null) {
        final cat = m2.group(1)!.trim();
        // ensure this is not a percent accidentally captured (pesoRegex may capture "20%" without % but we covered % above)
        final amt = double.tryParse(m2.group(2)!) ?? 0.0;
        out[cat] = amt;
      }
    }

    return out;
  }

  // --------------------------------------------------------------
  // FALLBACK: allocate proportionally to past spending (or equally if no history)
  // --------------------------------------------------------------
  Map<String, double> _fallbackProportionalAllocation(List<String> categories, Map<String, double> categoryTotals, double budget) {
    final Map<String, double> out = {};
    final totals = <String, double>{};
    double sumTotals = 0.0;
    for (var c in categories) {
      final t = (categoryTotals[c] ?? 0.0);
      totals[c] = t;
      sumTotals += t;
    }

    if (sumTotals <= 0) {
      // no history — split equally
      final equal = budget / categories.length;
      for (var c in categories) {
        out[c] = equal;
      }
      return _normalizeToBudget(out, budget);
    }

    // proportional
    for (var c in categories) {
      out[c] = (totals[c]! / sumTotals) * budget;
    }
    return _normalizeToBudget(out, budget);
  }

  // --------------------------------------------------------------
  // NORMALIZE: scale values so they sum exactly to budget and fix rounding
  // --------------------------------------------------------------
  Map<String, double> _normalizeToBudget(Map<String, double> allocations, double budget) {
    if (allocations.isEmpty) return allocations;

    // ensure only double values and positive
    final Map<String, double> cleaned = {};
    allocations.forEach((k, v) {
      cleaned[k] = (v.isFinite && v > 0) ? v : 0.0;
    });

    double sum = cleaned.values.fold(0.0, (a, b) => a + b);

    if (sum == 0) {
      // evenly distribute
      final even = budget / cleaned.length;
      final Map<String, double> out = { for (var k in cleaned.keys) k : even };
      return _roundAndFix(out, budget);
    }

    final scale = budget / sum;
    final Map<String, double> scaled = {};
    cleaned.forEach((k, v) {
      scaled[k] = v * scale;
    });

    return _roundAndFix(scaled, budget);
  }

  // Round to 2 decimals and distribute remainder due to rounding to the largest allocation
  Map<String, double> _roundAndFix(Map<String, double> allocations, double budget) {
    final Map<String, double> rounded = {};
    allocations.forEach((k, v) {
      rounded[k] = double.parse(v.toStringAsFixed(2));
    });

    double roundedSum = rounded.values.fold(0.0, (a, b) => a + b);
    double remainder = double.parse((budget - roundedSum).toStringAsFixed(2));

    if (remainder.abs() >= 0.01) {
      // add remainder to the largest allocation (to avoid adding very small fractional cents to many items)
      String largestKey = rounded.keys.first;
      double largestVal = rounded[largestKey]!;
      rounded.forEach((k, v) {
        if (v > largestVal) {
          largestVal = v;
          largestKey = k;
        }
      });
      rounded[largestKey] = double.parse((rounded[largestKey]! + remainder).toStringAsFixed(2));
    }

    // final safety: if still off by tiny fraction due to floating math, adjust
    double finalSum = rounded.values.fold(0.0, (a, b) => a + b);
    if ((budget - finalSum).abs() >= 0.01) {
      // distribute tiny diff proportionally
      final diff = budget - finalSum;
      final firstKey = rounded.keys.first;
      rounded[firstKey] = double.parse((rounded[firstKey]! + diff).toStringAsFixed(2));
    }

    return rounded;
  }

  // --------------------------------------------------------------
  // APPLY AI BUDGET → SAVE TO HIVE
  // --------------------------------------------------------------
  Future<void> _applyAiBudget() async {
    if (suggestedAllocations.isEmpty) return;

    final settingsBox = Hive.box(HiveBoxes.settingsBox);

    // Save as a Map<String,double>
    final Map<String, double> toSave = {};
    suggestedAllocations.forEach((k, v) {
      toSave[k] = (v.isFinite && v > 0) ? double.parse(v.toStringAsFixed(2)) : 0.0;
    });

    await settingsBox.put('budgetAllocations', toSave);

    if (!mounted) return;

    // Use a more modern SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2ecc71)),
            SizedBox(width: 8),
            Text(
              "AI Suggested Budget Applied Successfully!",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF192A56),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }
}