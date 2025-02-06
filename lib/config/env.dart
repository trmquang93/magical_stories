import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get googleAiApiKey => dotenv.env['GOOGLE_AI_API_KEY'] ?? '';

  static const String googleAiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
}
