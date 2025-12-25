import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressProvider extends ChangeNotifier {
  static const String _keyViewedWordsToday = 'viewedWordsToday';
  static const String _keyLastStudyDate = 'lastStudyDate';
  static const String _keyAdUnlockExpiry = 'adUnlockExpiry';
  static const String _keyIsPremium = 'isPremium';
  static const String _keyLevelProgress = 'levelProgress';
  static const String _keyScrollPositions = 'scrollPositions';

  static const int dailyLimit = 30;

  // 오늘 본 단어 ID 목록
  Set<int> _viewedWordsToday = {};
  DateTime? _lastStudyDate;
  DateTime? _adUnlockExpiry;
  bool _isPremium = false;
  bool _isLoaded = false;

  // 레벨별 진행도 (각 레벨에서 마지막으로 본 인덱스)
  Map<String, int> _levelProgress = {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0};

  // 레벨별 스크롤 위치
  Map<String, double> _scrollPositions = {
    'A1': 0.0,
    'A2': 0.0,
    'B1': 0.0,
    'B2': 0.0
  };

  // Getters
  int get viewedCountToday => _viewedWordsToday.length;
  int get remainingToday => dailyLimit - viewedCountToday;
  bool get hasReachedLimit => viewedCountToday >= dailyLimit;
  DateTime? get adUnlockExpiry => _adUnlockExpiry;
  bool get isPremium => _isPremium;
  bool get isLoaded => _isLoaded;

  bool get isAdUnlocked {
    if (_adUnlockExpiry == null) return false;
    return DateTime.now().isBefore(_adUnlockExpiry!);
  }

  bool get hasUnlimitedAccess => _isPremium || isAdUnlocked;

  ProgressProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    _isPremium = prefs.getBool(_keyIsPremium) ?? false;

    final lastDateStr = prefs.getString(_keyLastStudyDate);
    if (lastDateStr != null) {
      _lastStudyDate = DateTime.parse(lastDateStr);
    }

    final expiryStr = prefs.getString(_keyAdUnlockExpiry);
    if (expiryStr != null) {
      _adUnlockExpiry = DateTime.parse(expiryStr);
    }

    // 오늘 본 단어 목록 로드
    final viewedJson = prefs.getString(_keyViewedWordsToday);
    if (viewedJson != null) {
      final List<dynamic> list = jsonDecode(viewedJson);
      _viewedWordsToday = list.map((e) => e as int).toSet();
    }

    // 레벨별 진행도 로드
    final progressJson = prefs.getString(_keyLevelProgress);
    if (progressJson != null) {
      final Map<String, dynamic> map = jsonDecode(progressJson);
      _levelProgress = map.map((k, v) => MapEntry(k, v as int));
    }

    // 스크롤 위치 로드
    final scrollJson = prefs.getString(_keyScrollPositions);
    if (scrollJson != null) {
      final Map<String, dynamic> map = jsonDecode(scrollJson);
      _scrollPositions = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

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
        // 새 날 - 오늘 본 단어 초기화, 광고 잠금 해제 만료
        _viewedWordsToday.clear();
        _adUnlockExpiry = null;
      }
    }
    _lastStudyDate = now;
    _saveProgress();
  }

  // 단어를 볼 수 있는지 확인
  bool canViewWord(int wordId) {
    if (hasUnlimitedAccess) return true;
    // 이미 본 단어는 계속 볼 수 있음
    if (_viewedWordsToday.contains(wordId)) return true;
    // 오늘 30개 미만이면 새 단어 볼 수 있음
    return viewedCountToday < dailyLimit;
  }

  // 단어 조회 기록
  Future<void> markWordViewed(int wordId, String level) async {
    if (!_viewedWordsToday.contains(wordId)) {
      _viewedWordsToday.add(wordId);
      await _saveProgress();
      notifyListeners();
    }
  }

  // 레벨 진행도 업데이트
  Future<void> updateLevelProgress(String level, int index) async {
    if (index > (_levelProgress[level] ?? 0)) {
      _levelProgress[level] = index;
      await _saveProgress();
      notifyListeners();
    }
  }

  int getLevelProgress(String level) => _levelProgress[level] ?? 0;

  // 스크롤 위치 저장
  Future<void> saveScrollPosition(String level, double offset) async {
    _scrollPositions[level] = offset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyScrollPositions, jsonEncode(_scrollPositions));
  }

  double getScrollPosition(String level) => _scrollPositions[level] ?? 0.0;

  // 광고 시청 완료
  Future<void> onRewardedAdWatched() async {
    final now = DateTime.now();
    _adUnlockExpiry = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    await _saveProgress();
    notifyListeners();
  }

  // 프리미엄 설정
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await _saveProgress();
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, _isPremium);
    await prefs.setString(
        _keyViewedWordsToday, jsonEncode(_viewedWordsToday.toList()));
    await prefs.setString(_keyLevelProgress, jsonEncode(_levelProgress));
    await prefs.setString(_keyScrollPositions, jsonEncode(_scrollPositions));

    if (_lastStudyDate != null) {
      await prefs.setString(
          _keyLastStudyDate, _lastStudyDate!.toIso8601String());
    }
    if (_adUnlockExpiry != null) {
      await prefs.setString(
          _keyAdUnlockExpiry, _adUnlockExpiry!.toIso8601String());
    } else {
      await prefs.remove(_keyAdUnlockExpiry);
    }
  }
}
