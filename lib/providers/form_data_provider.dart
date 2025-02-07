import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormDataProvider with ChangeNotifier {
  String _childName = '';
  String _age = '';
  String _favoriteCharacter = '';
  String _theme = 'friendship';
  String _language = 'English';
  String _gender = 'boy';
  bool _isLoading = true;

  // Map display language names to language codes for text-to-speech
  static const Map<String, String> languageCodes = {
    'English': 'en-US',
    'Vietnamese': 'vi-VN',
    'Spanish': 'es-ES',
    'French': 'fr-FR',
    'German': 'de-DE',
    'Italian': 'it-IT',
    'Chinese': 'zh-CN',
    'Japanese': 'ja-JP',
    'Korean': 'ko-KR',
    'Russian': 'ru-RU',
    'Arabic': 'ar-SA',
    'Hindi': 'hi-IN',
    'Portuguese': 'pt-PT',
    'Dutch': 'nl-NL',
    'Polish': 'pl-PL',
    'Turkish': 'tr-TR',
    'Thai': 'th-TH',
    'Swedish': 'sv-SE',
    'Danish': 'da-DK',
    'Finnish': 'fi-FI',
    'Norwegian': 'nb-NO',
    'Greek': 'el-GR',
    'Hebrew': 'he-IL',
    'Indonesian': 'id-ID',
    'Malaysian': 'ms-MY',
    'Filipino': 'fil-PH',
    'Bengali': 'bn-IN',
    'Ukrainian': 'uk-UA',
    'Romanian': 'ro-RO',
    'Czech': 'cs-CZ',
    'Hungarian': 'hu-HU',
    'Bulgarian': 'bg-BG',
  };

  bool get isLoading => _isLoading;

  String getLanguageCode() {
    return languageCodes[_language] ?? 'en-US';
  }

  FormDataProvider() {
    _loadFormData();
  }

  String get childName => _childName;
  String get age => _age;
  String get favoriteCharacter => _favoriteCharacter;
  String get theme => _theme;
  String get language => _language;
  String get gender => _gender;

  Future<void> _loadFormData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _childName = prefs.getString('childName') ?? '';
      _age = prefs.getString('age') ?? '';
      _favoriteCharacter = prefs.getString('favoriteCharacter') ?? '';
      _theme = prefs.getString('theme') ?? 'friendship';
      _language = prefs.getString('language') ?? 'English';
      _gender = prefs.getString('gender') ?? 'boy';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveFormData({
    required String childName,
    required String age,
    required String favoriteCharacter,
    required String theme,
    required String language,
    required String gender,
  }) async {
    _childName = childName;
    _age = age;
    _favoriteCharacter = favoriteCharacter;
    _theme = theme;
    _language = language;
    _gender = gender;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('childName', childName);
    await prefs.setString('age', age);
    await prefs.setString('favoriteCharacter', favoriteCharacter);
    await prefs.setString('theme', theme);
    await prefs.setString('language', language);
    await prefs.setString('gender', gender);

    notifyListeners();
  }

  Future<void> clearFormData() async {
    _childName = '';
    _age = '';
    _favoriteCharacter = '';
    _theme = 'friendship';
    _language = 'English';
    _gender = 'boy';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('childName');
    await prefs.remove('age');
    await prefs.remove('favoriteCharacter');
    await prefs.remove('theme');
    await prefs.remove('language');
    await prefs.remove('gender');

    notifyListeners();
  }
}
