import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/settings_provider.dart';
import '../config/theme.dart';
import '../l10n/app_strings.dart';

class FavoritesFlashcardScreen extends StatefulWidget {
  final List<Word> favoriteWords;

  const FavoritesFlashcardScreen({super.key, required this.favoriteWords});

  @override
  State<FavoritesFlashcardScreen> createState() =>
      _FavoritesFlashcardScreenState();
}

class _FavoritesFlashcardScreenState extends State<FavoritesFlashcardScreen> {
  final PageController _pageController = PageController();

  late List<Word> _words;
  int _currentIndex = 0;
  final Set<int> _flippedCards = {};

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.favoriteWords)..shuffle(Random());
  }

  void _flipCard(int index) {
    setState(() {
      if (_flippedCards.contains(index)) {
        _flippedCards.remove(index);
      } else {
        _flippedCards.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().language;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(AppStrings.get('favorites_flashcards', lang)),
          ],
        ),
        actions: [
          // 예문 토글 버튼
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.showExample
                      ? Icons.format_quote
                      : Icons.format_quote_outlined,
                  color: settings.showExample ? Colors.amber[700] : Colors.grey,
                ),
                tooltip: settings.showExample ? 'Hide Example' : 'Show Example',
                onPressed: () => settings.toggleShowExample(),
              );
            },
          ),
          // 영어 뜻 토글 버튼
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              if (settings.language == 'en') return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  settings.showEnglishDefinition
                      ? Icons.translate
                      : Icons.translate_outlined,
                  color: settings.showEnglishDefinition
                      ? AppTheme.primaryColor
                      : Colors.grey,
                ),
                tooltip: settings.showEnglishDefinition
                    ? 'Hide English'
                    : 'Show English',
                onPressed: () => settings.toggleShowEnglishDefinition(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _words.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_currentIndex + 1}/${_words.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Flashcard
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _words.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final word = _words[index];
                final isFlipped = _flippedCards.contains(index);
                return _buildFlashcard(word, isFlipped, index);
              },
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppStrings.get('prev', lang)),
                ),
                ElevatedButton.icon(
                  onPressed: _currentIndex < _words.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(AppStrings.get('next', lang)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Word word, bool isFlipped, int index) {
    final settings = context.watch<SettingsProvider>();
    final translation = word.translations[settings.language];
    final levelColor = AppTheme.getLevelColor(word.level);

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isFlipped
              ? _buildBackCard(word, translation, levelColor, settings.language)
              : _buildFrontCard(word, levelColor, settings.language),
        ),
      ),
    );
  }

  Widget _buildFrontCard(Word word, Color levelColor, String lang) {
    final settings = context.watch<SettingsProvider>();

    return Card(
      key: const ValueKey('front'),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (settings.showExample) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  word.example,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const Spacer(),
            Text(
              AppStrings.get('tap_to_see_meaning', lang),
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Word word, translation, Color levelColor, String lang) {
    final settings = context.watch<SettingsProvider>();

    return Card(
      key: const ValueKey('back'),
      elevation: 4,
      color: levelColor.withOpacity(0.05),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.word,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    translation?.definition ?? word.definition,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (lang != 'en' && settings.showEnglishDefinition) ...[
                    const SizedBox(height: 8),
                    Text(
                      word.definition,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (settings.showExample) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      word.example,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (translation != null &&
                        translation.example.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        translation.example,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const Spacer(),
            Text(
              AppStrings.get('tap_to_flip_back', lang),
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
