import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoriteProvider extends ChangeNotifier {
  static const String _keyFavorites = 'favoriteWordIds';

  Set<int> _favoriteIds = {};
  bool _isLoaded = false;

  // Getters
  Set<int> get favoriteIds => _favoriteIds;
  bool get isLoaded => _isLoaded;
  int get count => _favoriteIds.length;

  FavoriteProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyFavorites);

    if (json != null) {
      final List<dynamic> list = jsonDecode(json);
      _favoriteIds = list.map((e) => e as int).toSet();
    }

    _isLoaded = true;
    notifyListeners();
  }

  bool isFavorite(int wordId) => _favoriteIds.contains(wordId);

  Future<void> toggleFavorite(int wordId) async {
    if (_favoriteIds.contains(wordId)) {
      _favoriteIds.remove(wordId);
    } else {
      _favoriteIds.add(wordId);
    }

    await _saveFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(int wordId) async {
    if (!_favoriteIds.contains(wordId)) {
      _favoriteIds.add(wordId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(int wordId) async {
    if (_favoriteIds.contains(wordId)) {
      _favoriteIds.remove(wordId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavorites, jsonEncode(_favoriteIds.toList()));
  }
}
