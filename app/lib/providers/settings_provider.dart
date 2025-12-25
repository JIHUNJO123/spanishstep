import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyIsDarkMode = 'isDarkMode';
  static const String _keyLanguage = 'language';

  bool _isDarkMode = false;
  String _language = 'ko'; // Default to Korean

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

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
}
