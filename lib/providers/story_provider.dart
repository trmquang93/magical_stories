import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../helpers/database_helper.dart';
import '../providers/form_data_provider.dart';

class Story {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String childName;
  final int childAge;
  final String language; // This is the language code (e.g., 'vi-VN', 'en-US')

  Story({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.childName,
    required this.childAge,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'childName': childName,
        'childAge': childAge,
        'language': language,
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        childName: json['childName'],
        childAge: json['childAge'],
        language:
            json['language'] ?? 'en-US', // Default to 'en-US' instead of 'en'
      );
}

class StoryProvider with ChangeNotifier {
  List<Story> _stories = [];
  bool _isLoading = false;
  String _error = '';
  DatabaseHelper? _db;

  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;
  String get error => _error;

  StoryProvider() {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        _db = DatabaseHelper.instance;
        await _loadStories();
        break; // If successful, exit the retry loop
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          _error =
              'Failed to initialize database after $maxRetries attempts: ${e.toString()}';
        } else {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
          continue;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadStories() async {
    if (_db == null) {
      throw Exception('Database not initialized');
    }

    try {
      // First try to get the count to verify database connection
      final count = await _db!.database
          .then((db) => db.rawQuery('SELECT COUNT(*) FROM stories'));
      if (count.isEmpty) {
        throw Exception('Failed to query database');
      }
      
      _stories = await _db!.getAllStories();
      _stories.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
    } catch (e) {
      _stories = [];
      throw Exception('Failed to load stories: ${e.toString()}');
    }
  }

  // Add a method to manually refresh stories
  Future<void> refreshStories() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _loadStories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _constructPrompt(String childName, int childAge,
      String favoriteCharacter, String theme, String language) {
    // Create a list of random story elements to make each story unique
    final List<String> timeSettings = [
      'morning',
      'afternoon',
      'evening',
      'night',
      'during a rainbow',
      'on a snowy day',
      'during a summer festival'
    ];
    final List<String> locations = [
      'magical forest',
      'cloud castle',
      'underwater kingdom',
      'floating island',
      'crystal cave',
      'enchanted garden'
    ];
    final List<String> supportingCharacters = [
      'wise owl',
      'playful dolphin',
      'friendly dragon',
      'magical butterfly',
      'ancient tree spirit',
      'star fairy'
    ];

    // Randomly select elements for this story
    final random = DateTime.now().millisecondsSinceEpoch;
    final timeSetting = timeSettings[random % timeSettings.length];
    final location = locations[(random ~/ 1000) % locations.length];
    final supportingCharacter =
        supportingCharacters[(random ~/ 1000000) % supportingCharacters.length];

    return '''
      You are a skilled children's story writer who specializes in creating unique and magical bedtime stories.
      Generate a completely new and different bedtime story in $language that has never been told before.
      
      Story elements to incorporate:
      - Main character: $favoriteCharacter
      - Time setting: $timeSetting
      - Location: $location
      - Supporting character: $supportingCharacter
      - Child's name: "$childName" (age $childAge)
      - Theme to explore: $theme
      
      Make this story unique by:
      1. Creating unexpected but child-friendly plot twists
      2. Using creative and vivid descriptions that paint a picture
      3. Including engaging dialogue between characters
      4. Adding elements of surprise and wonder
      5. Making the story about 500 words long
      
      Important requirements:
      1. Write the ENTIRE story in $language, including all descriptions and dialogue
      2. Use culturally appropriate references and storytelling styles for $language
      3. Ensure the moral lesson about $theme is woven naturally into the story
      4. Adapt character names and settings to be familiar to children who speak $language
      5. Use language complexity appropriate for bedtime stories in $language
      6. Create a unique and catchy title that captures the magic of this specific story

      Format your response exactly like this(start with "{", end with "}"):
      ```
      {
        "title": "Your Story Title in $language",
        "content": "Your complete story content in $language"
      }
      ```

      Make sure every single word, including the title and the "Once upon a time" equivalent, is in $language.
      If you are going to use the child's name, keep it as it is "$childName".
      
      Important: Make this story distinctly different from any previous stories you've generated.
      ''';
  }

  Future<void> generateStory({
    required String childName,
    required int childAge,
    required String favoriteCharacter,
    required String theme,
    required String language,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get the language code for text-to-speech and database storage
      final languageCode = FormDataProvider.languageCodes[language] ?? 'en-US';

      // Use display language name for story generation
      final prompt = _constructPrompt(
          childName, childAge, favoriteCharacter, theme, language);
      final response = await http.post(
        Uri.parse('${Env.googleAiEndpoint}?key=${Env.googleAiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 40,
            'topP': 0.8,
            'maxOutputTokens': 2048,
            'stopSequences': [],
            'candidateCount': 1,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String generatedText =
            data['candidates'][0]['content']['parts'][0]['text'].trim();
        // Clean up the response text and try to extract valid JSON
        if (!generatedText.startsWith('{')) {
          final startIndex = generatedText.indexOf('{');
          final endIndex = generatedText.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            generatedText = generatedText.substring(startIndex, endIndex + 1);
          }
        }

        // Try to extract the JSON object from the response
        // Sometimes the AI might include markdown code blocks or extra text
        final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
        final Match? jsonMatch = jsonRegex.firstMatch(generatedText);
        
        Map<String, dynamic> storyData;
        try {
          if (jsonMatch != null) {
            storyData = json.decode(jsonMatch.group(0)!);
          } else {
            storyData = json.decode(generatedText);
          }

          // Validate that we have both required fields
          if (!storyData.containsKey('title') ||
              !storyData.containsKey('content')) {
            throw FormatException('Response missing required fields');
          }
        } catch (e) {
          // If JSON parsing fails, use the entire text as content with a default title
          storyData = {
            'title': 'The Amazing Adventure',
            'content': generatedText,
          };
        }

        final story = Story(
          title: storyData['title'].toString().trim(),
          content: storyData['content'].toString().trim(),
          createdAt: DateTime.now(),
          childName: childName,
          childAge: childAge,
          language: languageCode,
        );

        await _db!.insertStory(story);
        await _loadStories(); // Reload stories from database
      } else {
        throw Exception('Failed to generate story: ${response.statusCode}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to generate story: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStory(int index) async {
    final story = _stories[index];
    if (story.id != null) {
      await _db!.deleteStory(story.id!);
      await _loadStories(); // Reload stories from database
    }
  }
}
