import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressProvider extends ChangeNotifier {
  static const String _keyCurrentWordId = 'currentWordId';
  static const String _keyScrollOffset = 'scrollOffset';
  static const String _keyLastStudyDate = 'lastStudyDate';
  static const String _keyAdUnlockExpiry = 'adUnlockExpiry';
  static const String _keyIsPremium = 'isPremium';
  static const String _keySelectedLevel = 'selectedLevel';
  
  static const int dailyLimit = 30;

  int _currentWordId = 1;
  double _scrollOffset = 0.0;
  DateTime? _lastStudyDate;
  DateTime? _adUnlockExpiry;
  bool _isPremium = false;
  String _selectedLevel = 'A1';
  bool _isLoaded = false;

  // Getters
  int get currentWordId => _currentWordId;
  double get scrollOffset => _scrollOffset;
  DateTime? get lastStudyDate => _lastStudyDate;
  DateTime? get adUnlockExpiry => _adUnlockExpiry;
  bool get isPremium => _isPremium;
  String get selectedLevel => _selectedLevel;
  bool get isLoaded => _isLoaded;

  // Check if ad unlock is active
  bool get isAdUnlocked {
    if (_adUnlockExpiry == null) return false;
    return DateTime.now().isBefore(_adUnlockExpiry!);
  }

  // Check if user has unlimited access
  bool get hasUnlimitedAccess => _isPremium || isAdUnlocked;

  // Get accessible word range
  int get startWordId => _currentWordId;
  int get endWordId => _currentWordId + dailyLimit - 1;

  ProgressProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentWordId = prefs.getInt(_keyCurrentWordId) ?? 1;
    _scrollOffset = prefs.getDouble(_keyScrollOffset) ?? 0.0;
    _isPremium = prefs.getBool(_keyIsPremium) ?? false;
    _selectedLevel = prefs.getString(_keySelectedLevel) ?? 'A1';
    
    final lastDateStr = prefs.getString(_keyLastStudyDate);
    if (lastDateStr != null) {
      _lastStudyDate = DateTime.parse(lastDateStr);
    }
    
    final expiryStr = prefs.getString(_keyAdUnlockExpiry);
    if (expiryStr != null) {
      _adUnlockExpiry = DateTime.parse(expiryStr);
    }
    
    // Check for daily reset
    _checkDailyReset();
    
    _isLoaded = true;
    notifyListeners();
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    if (_lastStudyDate != null) {
      final isNewDay = now.year != _lastStudyDate!.year ||
          now.month != _lastStudyDate!.month ||
          now.day != _lastStudyDate!.day;
      
      if (isNewDay) {
        // New day - reset ad unlock but keep word position
        _adUnlockExpiry = null;
      }
    }
    _lastStudyDate = now;
    _saveProgress();
  }

  // Check if a specific word is accessible
  bool canAccessWord(int wordId) {
    if (_isPremium || isAdUnlocked) return true;
    return wordId >= _currentWordId && wordId <= endWordId;
  }

  // Get lock reason for a word
  LockReason? getLockReason(int wordId) {
    if (canAccessWord(wordId)) return null;
    if (wordId < _currentWordId) return LockReason.alreadyLearned;
    return LockReason.notYetUnlocked;
  }

  // Update current word position
  Future<void> updateCurrentWord(int wordId) async {
    if (wordId > _currentWordId) {
      _currentWordId = wordId;
      await _saveProgress();
      notifyListeners();
    }
  }

  // Save scroll position
  Future<void> saveScrollPosition(double offset) async {
    _scrollOffset = offset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyScrollOffset, offset);
  }

  // Handle rewarded ad completion
  Future<void> onRewardedAdWatched() async {
    final now = DateTime.now();
    _adUnlockExpiry = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    await _saveProgress();
    notifyListeners();
  }

  // Handle premium purchase
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await _saveProgress();
    notifyListeners();
  }

  // Set selected level
  Future<void> setSelectedLevel(String level) async {
    _selectedLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedLevel, level);
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentWordId, _currentWordId);
    await prefs.setDouble(_keyScrollOffset, _scrollOffset);
    await prefs.setBool(_keyIsPremium, _isPremium);
    
    if (_lastStudyDate != null) {
      await prefs.setString(_keyLastStudyDate, _lastStudyDate!.toIso8601String());
    }
    if (_adUnlockExpiry != null) {
      await prefs.setString(_keyAdUnlockExpiry, _adUnlockExpiry!.toIso8601String());
    } else {
      await prefs.remove(_keyAdUnlockExpiry);
    }
  }
}

enum LockReason {
  alreadyLearned,
  notYetUnlocked,
}
