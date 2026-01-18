import 'package:google_generative_ai/google_generative_ai.dart';

class AiBudgetService {
  final String apiKey;

  AiBudgetService({required this.apiKey});

  Future<String> generateEnhanced503020({
    required double income,
    required Map<String, double> categories,
  }) async {
    final model = GenerativeModel(
      model: "gemini-2.5-flash-lite",
      apiKey: apiKey,
    );

    final prompt = """
You are a financial budgeting expert.

Use the 50/30/20 budget rule as a baseline:
- 50% for NEEDS
- 30% for WANTS
- 20% for SAVINGS/DEBT/GOALS

TASK:
1. Categorize the user's expenses (NEEDS, WANTS, SAVINGS).
2. Start with 50/30/20 but adjust percentages slightly based on actual category distribution.
3. Create 3 recommendations:
   A. Strict 50/30/20
   B. Balanced (adjusted)
   C. Savings-Focused

FORMAT STRICTLY LIKE THIS:

Option A – Strict 50/30/20:
Needs: X%
Wants: X%
Savings: X%
Breakdown:
Category – Amount

Option B – Balanced:
Needs: X%
Wants: X%
Savings: X%
Breakdown:
Category – Amount

Option C – Savings-Focused:
Needs: X%
Wants: X%
Savings: X%
Breakdown:
Category – Amount

User Income: $income

User Categories:
${categories.entries.map((e) => "- ${e.key}: ${e.value}").join("\n")}
""";

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    return response.text ?? "No AI response";
  }
}
