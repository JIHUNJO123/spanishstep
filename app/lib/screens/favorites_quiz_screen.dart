import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/settings_provider.dart';
import '../config/theme.dart';
import '../l10n/app_strings.dart';

class FavoritesQuizScreen extends StatefulWidget {
  final List<Word> favoriteWords;

  const FavoritesQuizScreen({super.key, required this.favoriteWords});

  @override
  State<FavoritesQuizScreen> createState() => _FavoritesQuizScreenState();
}

class _FavoritesQuizScreenState extends State<FavoritesQuizScreen> {
  late List<Word> _allWords;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _quizComplete = false;

  @override
  void initState() {
    super.initState();
    _allWords = List.from(widget.favoriteWords);
    _generateQuestions();
  }

  void _generateQuestions() {
    final random = Random();
    final shuffled = List<Word>.from(_allWords)..shuffle(random);
    final questionWords = shuffled.take(min(10, _allWords.length)).toList();

    _questions = questionWords.map((word) {
      // 4개의 선택지 생성 (정답 1개 + 오답 3개)
      final wrongAnswers = _allWords.where((w) => w.id != word.id).toList()
        ..shuffle(random);

      final options = [word, ...wrongAnswers.take(3)]..shuffle(random);
      final correctIndex = options.indexOf(word);

      return QuizQuestion(
        word: word,
        options: options,
        correctIndex: correctIndex,
      );
    }).toList();

    _currentIndex = 0;
    _correctCount = 0;
    _selectedAnswer = null;
    _showResult = false;
    _quizComplete = false;
  }

  void _selectAnswer(int index) {
    if (_showResult) return;

    setState(() {
      _selectedAnswer = index;
      _showResult = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    } else {
      setState(() => _quizComplete = true);
    }
  }

  void _restartQuiz() {
    _generateQuestions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().language;

    if (_quizComplete) {
      return _buildResultScreen(lang);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(AppStrings.get('favorites_quiz', lang)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildQuestionCard(lang),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String lang) {
    final question = _questions[_currentIndex];
    final settings = context.watch<SettingsProvider>();
    final translation = question.word.translations[settings.language];

    return Column(
      children: [
        // Question header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.get('question', lang)} ${_currentIndex + 1}/${_questions.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${AppStrings.get('score', lang)}: $_correctCount',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Question
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  translation?.definition ?? question.word.definition,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (settings.language != 'en') ...[
                  const SizedBox(height: 8),
                  Text(
                    question.word.definition,
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
        ),

        const SizedBox(height: 24),

        // Options
        Expanded(
          child: ListView.builder(
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == question.correctIndex;

              Color? backgroundColor;
              Color? borderColor;
              if (_showResult) {
                if (isCorrect) {
                  backgroundColor = Colors.green.withOpacity(0.1);
                  borderColor = Colors.green;
                } else if (isSelected) {
                  backgroundColor = Colors.red.withOpacity(0.1);
                  borderColor = Colors.red;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _selectAnswer(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(
                        color: borderColor ?? Colors.grey[300]!,
                        width: isSelected || (_showResult && isCorrect) ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.word,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  isSelected || (_showResult && isCorrect)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_showResult && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (_showResult && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Next button
        if (_showResult)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _currentIndex < _questions.length - 1
                      ? AppStrings.get('next', lang)
                      : 'Finish',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultScreen(String lang) {
    final percentage = (_correctCount / _questions.length * 100).round();
    final isGood = percentage >= 70;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('favorites_quiz', lang)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isGood ? Icons.celebration : Icons.sentiment_satisfied,
                size: 80,
                color: isGood ? Colors.amber : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.get('quiz_complete', lang),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('your_score', lang),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_correctCount/${_questions.length}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _restartQuiz,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppStrings.get('try_again', lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(AppStrings.get('back_home', lang)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final Word word;
  final List<Word> options;
  final int correctIndex;

  QuizQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
  });
}
