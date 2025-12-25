import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word.dart';

class WordService {
  static final WordService _instance = WordService._internal();
  factory WordService() => _instance;
  WordService._internal();

  final Map<String, List<Word>> _wordsByLevel = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // Level configurations
  static const Map<String, LevelConfig> levelConfigs = {
    'A1': LevelConfig(start: 1, count: 600, color: 0xFF4CAF50),
    'A2': LevelConfig(start: 601, count: 600, color: 0xFF8BC34A),
    'B1': LevelConfig(start: 1201, count: 1300, color: 0xFFFF9800),
    'B2': LevelConfig(start: 2501, count: 2500, color: 0xFFF44336),
  };

  Future<void> loadAllWords() async {
    if (_isLoaded) return;

    for (final level in ['a1', 'a2', 'b1', 'b2']) {
      try {
        final jsonString =
            await rootBundle.loadString('assets/data/${level}_words.json');
        final List<dynamic> jsonList = json.decode(jsonString);
        _wordsByLevel[level.toUpperCase()] =
            jsonList.map((e) => Word.fromJson(e)).toList();
      } catch (e) {
        print('Error loading $level words: $e');
        _wordsByLevel[level.toUpperCase()] = [];
      }
    }

    _isLoaded = true;
  }

  List<Word> getWordsForLevel(String level) {
    return _wordsByLevel[level.toUpperCase()] ?? [];
  }

  List<Word> getAllWords() {
    final all = <Word>[];
    for (final level in ['A1', 'A2', 'B1', 'B2']) {
      all.addAll(_wordsByLevel[level] ?? []);
    }
    return all;
  }

  Word? getWordById(int id) {
    for (final words in _wordsByLevel.values) {
      for (final word in words) {
        if (word.id == id) return word;
      }
    }
    return null;
  }

  List<Word> getWordsInRange(int startId, int endId) {
    final result = <Word>[];
    for (final words in _wordsByLevel.values) {
      for (final word in words) {
        if (word.id >= startId && word.id <= endId) {
          result.add(word);
        }
      }
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  int getTotalWordCount() {
    return _wordsByLevel.values.fold(0, (sum, list) => sum + list.length);
  }

  String getLevelForWordId(int id) {
    for (final entry in levelConfigs.entries) {
      final config = entry.value;
      if (id >= config.start && id < config.start + config.count) {
        return entry.key;
      }
    }
    return 'A1';
  }
}

class LevelConfig {
  final int start;
  final int count;
  final int color;

  const LevelConfig({
    required this.start,
    required this.count,
    required this.color,
  });

  int get end => start + count - 1;
}
