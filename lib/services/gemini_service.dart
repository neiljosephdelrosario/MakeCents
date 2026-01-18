import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;

  GeminiService(this.apiKey);

  late final GenerativeModel _model = GenerativeModel(
    model: "gemini-2.5-flash-lite",        // ✅ FREE & WORKING MODEL
    apiKey: 'AIzaSyASrRwcRPzqTPX2PPRC5ToJe0qBvUaD7N4'
  );

  /// Generates text using the Gemini API
  Future<String> generateBudgetSuggestion(String prompt) async {
    try {
      final response = await _model.generateContent([
        Content.text(prompt)
      ]);

      if (response.text == null || response.text!.isEmpty) {
        return "AI did not return a response.";
      }

      return response.text!;
    } catch (e) {
      return "Gemini API Error: $e";
    }
  }
}
