import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/favorite_provider.dart';
import '../providers/settings_provider.dart';
import '../services/word_service.dart';
import '../config/theme.dart';
import '../widgets/word_card.dart';
import '../l10n/app_strings.dart';
import 'favorites_flashcard_screen.dart';
import 'favorites_quiz_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final WordService _wordService = WordService();
  List<Word> _allWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    await _wordService.loadAllWords();
    setState(() {
      _allWords = _wordService.getAllWords();
      _isLoading = false;
    });
  }

  void _showNeedMoreFavorites(BuildContext context, String lang, int needed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            AppStrings.get('need_favorites', lang, params: {'count': needed})),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().language;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.red),
              const SizedBox(width: 8),
              Text(AppStrings.get('favorites', lang)),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppStrings.get('favorites', lang)),
          ],
        ),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, favorites, _) {
              final favoriteWords = _allWords
                  .where((word) => favorites.isFavorite(word.id))
                  .toList();

              if (favoriteWords.isEmpty) {
                return const SizedBox.shrink();
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 플래시카드 버튼
                  IconButton(
                    icon: const Icon(Icons.style),
                    tooltip: AppStrings.get('flashcards', lang),
                    onPressed: favoriteWords.length >= 4
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FavoritesFlashcardScreen(
                                  favoriteWords: favoriteWords,
                                ),
                              ),
                            );
                          }
                        : () => _showNeedMoreFavorites(context, lang, 4),
                  ),
                  // 퀴즈 버튼
                  IconButton(
                    icon: const Icon(Icons.quiz),
                    tooltip: AppStrings.get('quiz', lang),
                    onPressed: favoriteWords.length >= 4
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FavoritesQuizScreen(
                                  favoriteWords: favoriteWords,
                                ),
                              ),
                            );
                          }
                        : () => _showNeedMoreFavorites(context, lang, 4),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<FavoriteProvider, SettingsProvider>(
        builder: (context, favorites, settings, _) {
          if (!favorites.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          // 즐겨찾기한 단어 필터링
          final favoriteWords =
              _allWords.where((word) => favorites.isFavorite(word.id)).toList();

          if (favoriteWords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('no_favorites', lang),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get('add_favorites_hint', lang),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteWords.length,
            itemBuilder: (context, index) {
              final word = favoriteWords[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WordCard(
                  word: word,
                  language: settings.language,
                  isLocked: false,
                  showFavorite: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
