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
  final String gender;

  Story({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.childName,
    required this.childAge,
    required this.language,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'childName': childName,
        'childAge': childAge,
        'language': language,
        'gender': gender,
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
        gender: json['gender'] ?? 'boy', // Default to 'boy' if not specified
      );
}

class StoryProvider with ChangeNotifier {
  List<Story> _stories = [];
  bool _isLoading = false;
  String _error = '';
  DatabaseHelper? _db;
  String _sortBy = 'date';

  List<Story> get stories {
    final sortedStories = List<Story>.from(_stories);
    switch (_sortBy) {
      case 'date':
        sortedStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'theme':
        sortedStories.sort((a, b) => a.title.compareTo(b.title));
      // Note: Favorites sorting is commented out as it's not implemented in the Story model yet
      // case 'favorites':
      //   sortedStories.sort((a, b) => (b.isFavorite).toString().compareTo(a.isFavorite.toString()));
    }
    return sortedStories;
  }
  
  bool get isLoading => _isLoading;
  String get error => _error;

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

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
      String favoriteCharacter, String theme, String language, String gender) {
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

    // Determine pronouns based on gender
    final String pronounSubject = gender == 'girl'
        ? 'she'
        : gender == 'boy'
            ? 'he'
            : 'they';
    final String pronounObject = gender == 'girl'
        ? 'her'
        : gender == 'boy'
            ? 'him'
            : 'them';
    final String pronounPossessive = gender == 'girl'
        ? 'her'
        : gender == 'boy'
            ? 'his'
            : 'their';

    return '''
      You are a skilled children's story writer who specializes in creating unique and magical bedtime stories.
      Generate a completely new and different bedtime story in $language that has never been told before.
      
      Story elements to incorporate:
      - Main character: $favoriteCharacter
      - Time setting: $timeSetting
      - Location: $location
      - Supporting character: $supportingCharacter
      - Child's name: "$childName" (age $childAge)
      - Child's gender: $gender (use pronouns: $pronounSubject/$pronounObject/$pronounPossessive)
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
      7. Use gender-appropriate pronouns ($pronounSubject/$pronounObject/$pronounPossessive) when referring to $childName

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
    required String gender,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get the language code for text-to-speech and database storage
      final languageCode = FormDataProvider.languageCodes[language] ?? 'en-US';

      // Use display language name for story generation
      final prompt = _constructPrompt(
          childName, childAge, favoriteCharacter, theme, language, gender);

      Map<String, dynamic>? storyData;
      int maxRetries = 3;
      int currentTry = 0;

      while (currentTry < maxRetries && storyData == null) {
        currentTry++;

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

          final extractedData = _extractStoryData(generatedText);

          // Validate the response
          if (_isValidStoryData(extractedData, language)) {
            storyData = extractedData;
          } else if (currentTry < maxRetries) {
            // Wait before retrying with exponential backoff
            await Future.delayed(Duration(seconds: currentTry));
            continue;
          } else {
            throw Exception(
                'Failed to generate a valid story after $maxRetries attempts');
          }
        } else {
          if (currentTry == maxRetries) {
            throw Exception('Failed to generate story: ${response.statusCode}');
          }
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(seconds: currentTry));
          continue;
        }
      }

      if (storyData != null) {
        final story = Story(
          title: storyData['title'].toString().trim(),
          content: storyData['content'].toString().trim(),
          createdAt: DateTime.now(),
          childName: childName,
          childAge: childAge,
          language: languageCode,
          gender: gender,
        );

        await _db!.insertStory(story);
        await _loadStories(); // Reload stories from database
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to generate story: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isValidStoryData(Map<String, dynamic> storyData, String language) {
    if (!storyData.containsKey('title') || !storyData.containsKey('content')) {
      return false;
    }

    final title = storyData['title'].toString().trim();
    final content = storyData['content'].toString().trim();

    // Check if title and content are not empty
    if (title.isEmpty || content.isEmpty) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> _extractStoryData(String text) {
    // First, try to parse as direct JSON
    try {
      if (text.trim().startsWith('{') && text.trim().endsWith('}')) {
        return json.decode(text);
      }
    } catch (_) {
      // Continue to other parsing methods if JSON parsing fails
    }

    // Try to extract JSON object if it's wrapped in code blocks or has extra text
    final RegExp jsonRegex = RegExp(r'\{[\s\S]*?\}');
    final Match? jsonMatch = jsonRegex.firstMatch(text);
    if (jsonMatch != null) {
      try {
        final Map<String, dynamic> data = json.decode(jsonMatch.group(0)!);
        if (data.containsKey('title') && data.containsKey('content')) {
          return data;
        }
      } catch (_) {
        // Continue to other parsing methods if JSON extraction fails
      }
    }

    // Try to extract title and content using regex patterns
    String? title;
    String? content;

    // Look for title pattern in various formats
    final titlePatterns = [
      RegExp(r'title["\s:]+([^"\n]+)'),
      RegExp(r'Title:\s*(.+)'),
      RegExp(r'#\s*(.+)'), // Markdown title
    ];

    for (final pattern in titlePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        title = match.group(1)?.trim();
        break;
      }
    }

    // If no title found, take first line or generate default
    if (title == null) {
      title = text.split('\n').first.replaceAll(RegExp(r'[#*"`]'), '').trim();
      if (title.length > 50) {
        title = 'A Magical Story';
      }
    }

    // For content, remove any markdown code block syntax and title
    content = text
        .replaceAll(RegExp(r'```[^`]*```', multiLine: true), '')
        .replaceAll(RegExp(r'^#.*$', multiLine: true), '')
        .replaceAll(RegExp(r'title["\s:]+[^"\n]+'), '')
        .replaceAll(RegExp(r'content["\s:]+'), '')
        .replaceAll(RegExp(r'[{}\n\r]'), ' ')
        .trim();

    return {
      'title': title,
      'content': content,
    };
  }

  Future<void> deleteStory(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _db!.deleteStory(id);
      // Update local list instead of reloading from database
      _stories.removeWhere((story) => story.id == id);
    } catch (e) {
      _error = 'Failed to delete story: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
