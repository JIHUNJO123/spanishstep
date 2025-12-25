import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../config/theme.dart';
import '../services/tts_service.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final String language;
  final bool isLocked;
  final VoidCallback? onTap;

  const WordCard({
    super.key,
    required this.word,
    required this.language,
    this.isLocked = false,
    this.onTap,
  });

  void _speakWord() {
    if (!kIsWeb) {
      TtsService().speak(word.word);
    }
  }

  void _speakExample() {
    if (!kIsWeb) {
      TtsService().speak(word.example);
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = AppTheme.getLevelColor(word.level);

    // 잠긴 카드는 내용을 숨김
    if (isLocked) {
      return _buildLockedCard(context, levelColor);
    }

    return _buildUnlockedCard(context, levelColor);
  }

  Widget _buildLockedCard(BuildContext context, Color levelColor) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '#${word.id}',
                style: TextStyle(
                  color: levelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Watch ad to unlock',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap here',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedCard(BuildContext context, Color levelColor) {
    // 선택된 언어의 번역 가져오기
    final translation = word.translations[language];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Word + ID badge + TTS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              word.word,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!kIsWeb)
                            IconButton(
                              icon: Icon(Icons.volume_up,
                                  color: AppTheme.primaryColor),
                              onPressed: _speakWord,
                              tooltip: 'Pronounce',
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.partOfSpeech,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${word.id}',
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 번역 (선택된 언어)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLanguageLabel(language),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    translation?.definition ?? word.definition,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),

            // 영어 정의 (선택 언어가 영어가 아닐 때만)
            if (language != 'en') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'English',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.definition,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 예문
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote,
                          size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Example',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (!kIsWeb)
                        GestureDetector(
                          onTap: _speakExample,
                          child: Icon(Icons.volume_up,
                              size: 18, color: Colors.amber[700]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 스페인어 예문
                  Text(
                    word.example,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // 번역된 예문
                  if (translation != null &&
                      translation.example.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      translation.example,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageLabel(String lang) {
    switch (lang) {
      case 'ko':
        return '한국어';
      case 'ja':
        return '日本語';
      case 'zh':
        return '中文';
      case 'pt':
        return 'Português';
      case 'fr':
        return 'Français';
      case 'en':
      default:
        return 'English';
    }
  }
}
