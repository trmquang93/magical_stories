import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';

class Story {
  final String title;
  final String content;
  final DateTime createdAt;

  Story({
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        title: json['title'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class StoryProvider with ChangeNotifier {
  List<Story> _stories = [];
  bool _isLoading = false;
  String _error = '';

  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;
  String get error => _error;

  StoryProvider() {
    _loadStories();
  }

  Future<void> _loadStories() async {
    final prefs = await SharedPreferences.getInstance();
    final storiesJson = prefs.getStringList('stories') ?? [];
    _stories =
        storiesJson.map((story) => Story.fromJson(json.decode(story))).toList();
    notifyListeners();
  }

  Future<void> _saveStories() async {
    final prefs = await SharedPreferences.getInstance();
    final storiesJson =
        _stories.map((story) => json.encode(story.toJson())).toList();
    await prefs.setStringList('stories', storiesJson);
  }

  String _constructPrompt(
      String childName, int childAge, String favoriteCharacter, String theme) {
    return '''Create a short, engaging bedtime story for a $childAge-year-old child named $childName. 
    The story should feature their favorite character/animal '$favoriteCharacter' and teach a lesson about '$theme'.
    The story should be child-friendly, positive, and approximately 300-400 words.
    Format the response as JSON with 'title' and 'content' fields.
    Make the title creative and engaging for children.''';
  }

  Future<void> generateStory({
    required String childName,
    required int childAge,
    required String favoriteCharacter,
    required String theme,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prompt =
          _constructPrompt(childName, childAge, favoriteCharacter, theme);
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
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
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
            data['candidates'][0]['content']['parts'][0]['text'];

        // Parse the JSON response from the AI
        Map<String, dynamic> storyData;
        try {
          storyData = json.decode(generatedText);
        } catch (e) {
          // Fallback if AI doesn't return proper JSON
          storyData = {
            'title': 'The Amazing Adventure',
            'content': generatedText,
          };
        }

        final story = Story(
          title: storyData['title'] ?? 'The Amazing Adventure',
          content: storyData['content'] ?? generatedText,
          createdAt: DateTime.now(),
        );

        _stories.insert(0, story);
        await _saveStories();
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

  void deleteStory(int index) async {
    _stories.removeAt(index);
    await _saveStories();
    notifyListeners();
  }
}
