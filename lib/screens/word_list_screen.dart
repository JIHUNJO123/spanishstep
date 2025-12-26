import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/word_service.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../config/theme.dart';
import '../widgets/word_card.dart';

class WordListScreen extends StatefulWidget {
  final String level;

  const WordListScreen({super.key, required this.level});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final WordService _wordService = WordService();
  final AdService _adService = AdService();
  final ScrollController _scrollController = ScrollController();

  List<Word> _words = [];
  bool _isLoading = true;
  bool _isAdLoading = false;
  bool _scrollRestored = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
    _adService.loadRewardedAd();
    _scrollController.addListener(_onScroll);
  }

  void _restoreScrollPosition() {
    if (_scrollRestored) return;
    _scrollRestored = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<ProgressProvider>();
      final savedOffset = progress.getScrollPosition(widget.level);
      if (savedOffset > 0 && _scrollController.hasClients) {
        _scrollController.jumpTo(savedOffset);
      }
    });
  }

  void _onScroll() {
    final progress = context.read<ProgressProvider>();
    progress.saveScrollPosition(widget.level, _scrollController.offset);

    // 현재 보이는 단어 인덱스 계산 (대략적인 카드 높이 기준)
    if (_words.isNotEmpty && _scrollController.hasClients) {
      // 카드 높이(약 200) + 패딩(12) + 상단 패딩(16) 고려
      const cardHeight = 212.0;
      final currentIndex = (_scrollController.offset / cardHeight).floor();
      final clampedIndex = currentIndex.clamp(0, _words.length - 1);

      // 더 앞으로 진행했을 때만 업데이트
      progress.updateLevelProgress(widget.level, clampedIndex);
    }
  }

  Future<void> _loadWords() async {
    await _wordService.loadAllWords();
    setState(() {
      _words = _wordService.getWordsForLevel(widget.level);
      _isLoading = false;
    });
    // 데이터 로드 후 스크롤 복원
    _restoreScrollPosition();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showUnlockDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Unlock More Words',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAdLoading ? null : () => _handleWatchAd(ctx),
                    icon: _isAdLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_circle_outline),
                    label: Text(_isAdLoading
                        ? 'Loading...'
                        : 'Watch Ad to Unlock'),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handlePurchase();
                    },
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Remove Ads Forever'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleWatchAd(BuildContext dialogContext) async {
    setState(() => _isAdLoading = true);

    final success = await _adService.showRewardedAd(
      onRewarded: () {
        context.read<ProgressProvider>().onRewardedAdWatched();
      },
    );

    setState(() => _isAdLoading = false);

    if (success) {
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Unlimited access until midnight!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not ready. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _handlePurchase() async {
    final purchaseService = PurchaseService.instance;
    
    if (!purchaseService.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('In-app purchases not available')),
        );
      }
      return;
    }

    // 구매 시작
    final success = await purchaseService.buyRemoveAds();
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(purchaseService.errorMessage ?? 'Purchase failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.level)),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${_words.length} words'),
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
                onPressed: () {
                  settings.toggleShowExample();
                },
              );
            },
          ),
          // 영어 뜻 토글 버튼
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              // 언어가 영어일 때는 토글 버튼 숨김
              if (settings.language == 'en') {
                return const SizedBox.shrink();
              }
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
                onPressed: () {
                  settings.toggleShowEnglishDefinition();
                },
              );
            },
          ),
          Consumer<ProgressProvider>(
            builder: (context, progress, _) {
              // 무제한 액세스일 때만 표시
              if (progress.hasUnlimitedAccess) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.all_inclusive, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Unlimited',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<ProgressProvider, SettingsProvider>(
        builder: (context, progress, settings, _) {
          // 데이터 로드 완료 대기
          if (!progress.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _words.length,
            itemBuilder: (context, index) {
              final word = _words[index];

              // 짝수 인덱스(0, 2, 4...)는 무료, 홀수 인덱스(1, 3, 5...)는 잠금
              // 무제한 액세스가 있으면 모든 단어 볼 수 있음
              final isLocked = !progress.hasUnlimitedAccess && (index % 2 == 1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WordCard(
                  word: word,
                  language: settings.language,
                  isLocked: isLocked,
                  onTap: isLocked ? () => _showUnlockDialog() : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
