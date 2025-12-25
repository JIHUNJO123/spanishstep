import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/word_service.dart';
import '../services/ad_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadWords();
    _adService.loadRewardedAd();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<ProgressProvider>();
      final savedOffset = progress.getScrollPosition(widget.level);
      if (savedOffset > 0 && _scrollController.hasClients) {
        _scrollController.jumpTo(savedOffset);
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    context
        .read<ProgressProvider>()
        .saveScrollPosition(widget.level, _scrollController.offset);
  }

  Future<void> _loadWords() async {
    await _wordService.loadAllWords();
    setState(() {
      _words = _wordService.getWordsForLevel(widget.level);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showUnlockDialog() {
    final progress = context.read<ProgressProvider>();

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
                  'Daily Limit Reached',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'ve viewed ${progress.viewedCountToday} of ${ProgressProvider.dailyLimit} free words today.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                      ? 'Tap below to unlock (test mode on web)'
                      : 'Watch an ad to unlock unlimited access until midnight!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
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
                    label: Text(
                        _isAdLoading ? 'Loading...' : 'Watch Ad to Unlock'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Remove Ads Forever - \$1.99'),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Resets at midnight',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
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
          Consumer<ProgressProvider>(
            builder: (context, progress, _) {
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
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progress.hasReachedLimit
                      ? Colors.red.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      progress.hasReachedLimit ? Icons.lock : Icons.visibility,
                      color:
                          progress.hasReachedLimit ? Colors.red : Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.viewedCountToday}/${ProgressProvider.dailyLimit}',
                      style: TextStyle(
                        color:
                            progress.hasReachedLimit ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<ProgressProvider, SettingsProvider>(
        builder: (context, progress, settings, _) {
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _words.length,
            itemBuilder: (context, index) {
              final word = _words[index];
              final canView = progress.canViewWord(word.id);
              final isLocked = !canView;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Builder(
                  builder: (context) {
                    // 잠기지 않은 카드가 화면에 보이면 자동으로 조회 카운트
                    if (!isLocked) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        progress.markWordViewed(word.id, widget.level);
                        progress.updateLevelProgress(widget.level, index);
                      });
                    }
                    return WordCard(
                      word: word,
                      language: settings.language,
                      isLocked: isLocked,
                      onTap: isLocked ? () => _showUnlockDialog() : null,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
