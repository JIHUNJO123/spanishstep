import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../config/theme.dart';
import '../providers/favorite_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final String language;
  final bool isLocked;
  final VoidCallback? onTap;
  final bool showFavorite;

  const WordCard({
    super.key,
    required this.word,
    required this.language,
    this.isLocked = false,
    this.onTap,
    this.showFavorite = true,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  word.level,
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Watch ad to unlock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const Text(
                '(Resets at midnight)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tap here',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
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
            // Header: Word + Favorite + Level badge
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
                          if (showFavorite)
                            Consumer<FavoriteProvider>(
                              builder: (context, favorites, _) {
                                final isFav = favorites.isFavorite(word.id);
                                return IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFav ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () {
                                    favorites.toggleFavorite(word.id);
                                    final msg = isFav
                                        ? AppStrings.get(
                                            'removed_from_favorites', language)
                                        : AppStrings.get(
                                            'added_to_favorites', language);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  iconSize: 24,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
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
              child: Text(
                translation?.definition ?? word.definition,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),

            // 영어 정의 (선택 언어가 영어가 아니고, showEnglishDefinition이 true일 때만)
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                if (language == 'en' || !settings.showEnglishDefinition) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      word.definition,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // 예문
            // 예문 (showExample이 true일 때만)
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                if (!settings.showExample) {
                  return const SizedBox.shrink();
                }
                return Container(
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
                      Text(
                        word.example,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // 번역된 예문 표시
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
                );
              },
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
