import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  // Default values
  static const int _defaultDailyLimit = 15;
  static const String _defaultAgeRange = '3-5';
  static const bool _defaultNotifications = true;
  static const bool _defaultIsDarkMode = false;
  static const double _defaultFontSize = 16.0;
  static const bool _defaultTextToSpeech = false;

  SettingsProvider(this._prefs) {
    // Load saved settings
    _dailyLimit = _prefs.getInt('dailyLimit') ?? _defaultDailyLimit;
    _ageRange = _prefs.getString('ageRange') ?? _defaultAgeRange;
    _notifications = _prefs.getBool('notifications') ?? _defaultNotifications;
    _isDarkMode = _prefs.getBool('isDarkMode') ?? _defaultIsDarkMode;
    _fontSize = _prefs.getDouble('fontSize') ?? _defaultFontSize;
    _isTextToSpeechEnabled =
        _prefs.getBool('textToSpeech') ?? _defaultTextToSpeech;
  }

  // Daily story time limit in minutes
  int _dailyLimit = _defaultDailyLimit;
  int get dailyLimit => _dailyLimit;

  // Age range for content filtering
  String _ageRange = _defaultAgeRange;
  String get ageRange => _ageRange;

  // Notification settings
  bool _notifications = _defaultNotifications;
  bool get notifications => _notifications;

  // Theme settings
  bool _isDarkMode = _defaultIsDarkMode;
  bool get isDarkMode => _isDarkMode;

  // Font settings
  double _fontSize = _defaultFontSize;
  double get fontSize => _fontSize;

  // Text-to-speech settings
  bool _isTextToSpeechEnabled = _defaultTextToSpeech;
  bool get isTextToSpeechEnabled => _isTextToSpeechEnabled;

  // Methods to update settings
  Future<void> setDailyLimit(int minutes) async {
    _dailyLimit = minutes;
    await _prefs.setInt('dailyLimit', minutes);
    notifyListeners();
  }

  Future<void> setAgeRange(String range) async {
    _ageRange = range;
    await _prefs.setString('ageRange', range);
    notifyListeners();
  }

  Future<void> setNotifications(bool enabled) async {
    _notifications = enabled;
    await _prefs.setBool('notifications', enabled);
    notifyListeners();
  }

  // PIN management
  Future<bool> verifyPIN(String pin) async {
    final savedPin = _prefs.getString('pin');
    return savedPin == pin;
  }

  Future<void> setPIN(String pin) async {
    await _prefs.setString('pin', pin);
    notifyListeners();
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.clear();
    _dailyLimit = _defaultDailyLimit;
    _ageRange = _defaultAgeRange;
    _notifications = _defaultNotifications;
    _isDarkMode = _defaultIsDarkMode;
    _fontSize = _defaultFontSize;
    _isTextToSpeechEnabled = _defaultTextToSpeech;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  Future<void> toggleTextToSpeech() async {
    _isTextToSpeechEnabled = !_isTextToSpeechEnabled;
    await _prefs.setBool('textToSpeech', _isTextToSpeechEnabled);
    notifyListeners();
  }
}
