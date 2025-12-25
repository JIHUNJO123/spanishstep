import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/settings_provider.dart';
import '../services/word_service.dart';
import '../config/theme.dart';

class QuizScreen extends StatefulWidget {
  final String level;

  const QuizScreen({super.key, required this.level});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final WordService _wordService = WordService();

  List<Word> _allWords = [];
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _quizComplete = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    await _wordService.loadAllWords();
    final words = _wordService.getWordsForLevel(widget.level);
    _allWords = List.from(words);
    _generateQuestions();
    setState(() => _isLoading = false);
  }

  void _generateQuestions() {
    final random = Random();
    final shuffled = List<Word>.from(_allWords)..shuffle(random);
    final questionWords = shuffled.take(10).toList();

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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.level} Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizComplete) {
      return _buildResultScreen();
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
            const Text('Quiz'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_correctCount / ${_questions.length}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final question = _questions[_currentIndex];
          final translation = question.word.translations[settings.language];

          return Column(
            children: [
              // Progress
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Q${_currentIndex + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _questions.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                            AppTheme.getLevelColor(widget.level)),
                      ),
                    ),
                  ],
                ),
              ),

              // Question
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'What does this word mean?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              question.word.word,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.word.partOfSpeech,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Options
                      Expanded(
                        child: ListView.builder(
                          itemCount: question.options.length,
                          itemBuilder: (context, index) {
                            final option = question.options[index];
                            final optionTranslation =
                                option.translations[settings.language];
                            final isSelected = _selectedAnswer == index;
                            final isCorrect = index == question.correctIndex;

                            Color? bgColor;
                            Color? borderColor;

                            if (_showResult) {
                              if (isCorrect) {
                                bgColor = Colors.green.withOpacity(0.2);
                                borderColor = Colors.green;
                              } else if (isSelected && !isCorrect) {
                                bgColor = Colors.red.withOpacity(0.2);
                                borderColor = Colors.red;
                              }
                            } else if (isSelected) {
                              bgColor = AppTheme.primaryColor.withOpacity(0.1);
                              borderColor = AppTheme.primaryColor;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _selectAnswer(index),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderColor ??
                                          Colors.grey.withOpacity(0.3),
                                      width: isSelected ||
                                              (_showResult && isCorrect)
                                          ? 2
                                          : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected ||
                                                  (_showResult && isCorrect)
                                              ? (isCorrect
                                                  ? Colors.green
                                                  : Colors.red)
                                              : Colors.grey.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: _showResult
                                              ? Icon(
                                                  isCorrect
                                                      ? Icons.check
                                                      : (isSelected
                                                          ? Icons.close
                                                          : null),
                                                  color: Colors.white,
                                                  size: 18,
                                                )
                                              : Text(
                                                  String.fromCharCode(
                                                      65 + index),
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.grey[600],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          optionTranslation?.definition ??
                                              option.definition,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ||
                                                    (_showResult && isCorrect)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentIndex < _questions.length - 1
                                  ? 'Next Question'
                                  : 'See Results',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_correctCount / _questions.length * 100).round();
    final isGood = percentage >= 70;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.level} Quiz Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isGood
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGood ? Icons.emoji_events : Icons.school,
                  size: 80,
                  color: isGood ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isGood ? 'Great Job!' : 'Keep Practicing!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_correctCount / ${_questions.length} correct',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isGood ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _restartQuiz,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
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
