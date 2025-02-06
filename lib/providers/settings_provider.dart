import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  bool _isTextToSpeechEnabled = false;

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  bool get isTextToSpeechEnabled => _isTextToSpeechEnabled;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _isTextToSpeechEnabled = prefs.getBool('isTextToSpeechEnabled') ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  Future<void> toggleTextToSpeech() async {
    _isTextToSpeechEnabled = !_isTextToSpeechEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTextToSpeechEnabled', _isTextToSpeechEnabled);
    notifyListeners();
  }
}
