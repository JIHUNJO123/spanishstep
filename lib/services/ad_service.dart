import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // AdMob IDs - Production
  static const String _prodRewardedAdUnitIdIOS =
      'ca-app-pub-5837885590326347/5713859000';
  static const String _prodRewardedAdUnitIdAndroid =
      'ca-app-pub-5837885590326347/2170377421';

  // Test IDs for development
  static const String _testRewardedAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedAdUnitIdIOS =
      'ca-app-pub-3940256099942544/1712485313';

  // 디버그 모드에서 테스트 광고 ID 사용
  static String get rewardedAdUnitIdAndroid => 
      kDebugMode ? _testRewardedAdUnitIdAndroid : _prodRewardedAdUnitIdAndroid;
  static String get rewardedAdUnitIdIOS => 
      kDebugMode ? _testRewardedAdUnitIdIOS : _prodRewardedAdUnitIdIOS;

  bool get isAdReady => _rewardedAd != null;

  void loadRewardedAd() {
    // Skip on web
    if (kIsWeb) return;
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    _loadAd();
  }

  void _loadAd() {
    // 플랫폼별 광고 ID 선택
    final String adUnitId = Platform.isIOS 
        ? rewardedAdUnitIdIOS 
        : rewardedAdUnitIdAndroid;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: ${error.message}');
          _isLoading = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required Function onRewarded,
  }) async {
    // On web, just grant the reward (for testing)
    if (kIsWeb) {
      onRewarded();
      return true;
    }

    if (_rewardedAd == null) {
      loadRewardedAd();
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );

    return true;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
