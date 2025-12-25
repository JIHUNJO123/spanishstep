import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/settings_provider.dart';
import '../services/word_service.dart';
import '../config/theme.dart';

class FlashcardScreen extends StatefulWidget {
  final String level;

  const FlashcardScreen({super.key, required this.level});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final WordService _wordService = WordService();
  final PageController _pageController = PageController();

  List<Word> _words = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final Set<int> _flippedCards = {};

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    await _wordService.loadAllWords();
    final words = _wordService.getWordsForLevel(widget.level);
    // 셔플해서 랜덤 순서로
    words.shuffle(Random());
    setState(() {
      _words = words.take(20).toList(); // 20개만
      _isLoading = false;
    });
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.level} Flashcards')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.getLevelColor(widget.level),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.level,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Flashcards'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () {
              setState(() {
                _words.shuffle(Random());
                _flippedCards.clear();
                _pageController.jumpToPage(0);
                _currentIndex = 0;
              });
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
                Text(
                  '${_currentIndex + 1} / ${_words.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _words.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(
                        AppTheme.getLevelColor(widget.level)),
                  ),
                ),
              ],
            ),
          ),

          // Flashcards
          Expanded(
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    final word = _words[index];
                    final isFlipped = _flippedCards.contains(index);
                    final translation = word.translations[settings.language];

                    return GestureDetector(
                      onTap: () => _flipCard(index),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isFlipped
                              ? _buildBackCard(
                                  word, translation, settings.language)
                              : _buildFrontCard(word),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Prev'),
                ),
                Text(
                  'Tap card to flip',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                ElevatedButton.icon(
                  onPressed: _currentIndex < _words.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(Word word) {
    return Card(
      key: const ValueKey('front'),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              word.partOfSpeech,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
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
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tap to see meaning',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Word word, Translation? translation, String language) {
    return Card(
      key: const ValueKey('back'),
      elevation: 8,
      color: AppTheme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              translation?.definition ?? word.definition,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (language != 'en') ...[
              const SizedBox(height: 16),
              Text(
                word.definition,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            if (translation?.example.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  translation!.example,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tap to flip back',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
