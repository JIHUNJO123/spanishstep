import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/word_service.dart';
import '../services/ad_service.dart';
import '../config/theme.dart';
import '../widgets/word_card.dart';
import '../widgets/lock_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    _loadWords();
    _adService.loadRewardedAd();
    
    // Restore scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<ProgressProvider>();
      if (progress.scrollOffset > 0) {
        _scrollController.jumpTo(progress.scrollOffset);
      }
    });

    // Save scroll position on scroll
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    context.read<ProgressProvider>().saveScrollPosition(_scrollController.offset);
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

  void _showLockDialog(LockReason reason) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LockOverlay(
        reason: reason,
        onWatchAd: _handleWatchAd,
        onUpgrade: _handleUpgrade,
      ),
    );
  }

  Future<void> _handleWatchAd() async {
    Navigator.pop(context);
    
    final success = await _adService.showRewardedAd(
      onRewarded: () {
        context.read<ProgressProvider>().onRewardedAdWatched();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Unlimited access until midnight!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready. Please try again.'),
        ),
      );
    }
  }

  void _handleUpgrade() {
    Navigator.pop(context);
    // TODO: Implement in-app purchase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
      ),
    );
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
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.lock_open, color: Colors.green),
                );
              }
              return IconButton(
                icon: const Icon(Icons.play_circle_outline),
                tooltip: 'Watch ad for unlimited access',
                onPressed: () => _showLockDialog(LockReason.notYetUnlocked),
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
              final lockReason = progress.getLockReason(word.id);
              final isLocked = lockReason != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: isLocked ? () => _showLockDialog(lockReason) : null,
                  child: Stack(
                    children: [
                      WordCard(
                        word: word,
                        language: settings.language,
                        isLocked: isLocked,
                        onViewed: () {
                          if (!isLocked) {
                            progress.updateCurrentWord(word.id);
                          }
                        },
                      ),
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    lockReason == LockReason.alreadyLearned
                                        ? 'Already learned'
                                        : 'Locked',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap to unlock',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
