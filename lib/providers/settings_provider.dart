import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyIsDarkMode = 'isDarkMode';
  static const String _keyLanguage = 'language';
  static const String _keyShowEnglish = 'showEnglishDefinition';
  static const String _keyShowExample = 'showExample';
  static const String _keyTtsVolume = 'ttsVolume';
  static const String _keyTtsSpeed = 'ttsSpeed';

  bool _isDarkMode = false;
  String _language = 'ko'; // Default to Korean
  bool _showEnglishDefinition = true;
  bool _showExample = true;
  double _ttsVolume = 1.0; // 0.0 - 1.0
  double _ttsSpeed = 0.45; // 0.0 - 1.0

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get showEnglishDefinition => _showEnglishDefinition;
  bool get showExample => _showExample;
  double get ttsVolume => _ttsVolume;
  double get ttsSpeed => _ttsSpeed;

  // Available languages
  static const Map<String, String> languages = {
    'ko': '한국어',
    'ja': '日本語',
    'zh': '中文',
    'pt': 'Português',
    'fr': 'Français',
    'en': 'English',
  };

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyIsDarkMode) ?? false;
    _language = prefs.getString(_keyLanguage) ?? 'ko';
    _showEnglishDefinition = prefs.getBool(_keyShowEnglish) ?? true;
    _showExample = prefs.getBool(_keyShowExample) ?? true;
    _ttsVolume = prefs.getDouble(_keyTtsVolume) ?? 1.0;
    _ttsSpeed = prefs.getDouble(_keyTtsSpeed) ?? 0.45;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkMode, value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> setShowEnglishDefinition(bool value) async {
    _showEnglishDefinition = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowEnglish, value);
    notifyListeners();
  }

  void toggleShowEnglishDefinition() {
    setShowEnglishDefinition(!_showEnglishDefinition);
  }

  Future<void> setShowExample(bool value) async {
    _showExample = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowExample, value);
    notifyListeners();
  }

  void toggleShowExample() {
    setShowExample(!_showExample);
  }

  Future<void> setTtsVolume(double value) async {
    _ttsVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsVolume, value);
    notifyListeners();
  }

  Future<void> setTtsSpeed(double value) async {
    _ttsSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsSpeed, value);
    notifyListeners();
  }
}
