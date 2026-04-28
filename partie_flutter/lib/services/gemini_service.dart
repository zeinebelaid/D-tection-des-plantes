// lib/services/gemini_service.dart
import 'dart:async';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static void init(String apiKey) {
    Gemini.init(apiKey: apiKey);
  }
}

Stream<String> streamText(String prompt,
    {String model = 'gemini-2.0-flash-001'}) {
  return Gemini.instance
      .streamGenerateContent(prompt, modelName: model)
      .map((event) => event.output ?? '');
}
