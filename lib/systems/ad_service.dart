import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

/// Monetization architecture: rewarded "continue" ads and level-complete
/// interstitials, rate-limited so ads never interrupt gameplay itself.
///
/// Uses Google's official public TEST ad unit ids. Swap [_rewardedAdUnitId]
/// and [_interstitialAdUnitId] for real AdMob ids before release.
class AdService {
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Cross-promo link shown instead of a real ad slot when no real ad is
  /// available (typically: offline, or AdMob failed to load). This is a
  /// house ad: opening it does not grant any in-game reward, since there
  /// is no ad-network verification behind it. The UTM parameters let
  /// cefrify.uz attribute traffic back to this in-app placement.
  static const String houseAdUrl =
      'https://cefrify.uz/?utm_source=mazedrop&utm_medium=house_ad&utm_campaign=offline_fallback';

  /// Show an interstitial at most once every [interstitialFrequency] level
  /// completions, never on every level.
  static const int interstitialFrequency = 3;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  int _levelCompletionsSinceLastAd = 0;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewarded();
      _loadInterstitial();
    } catch (e) {
      if (kDebugMode) debugPrint('AdService: initialize failed: $e');
    }
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('AdService: rewarded load failed: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('AdService: interstitial load failed: $error');
          }
          _interstitialAd = null;
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardedAd != null;

  /// Shows the rewarded "continue after death" ad. [onReward] fires only
  /// once the user actually earns the reward; it is never granted for a
  /// merely-skipped or failed ad.
  Future<bool> showRewardedContinue({
    required VoidCallback onReward,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) return false;
    _rewardedAd = null;
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        onReward();
      },
    );
    return earned;
  }

  /// Called after a level completes. Shows an interstitial only every
  /// [interstitialFrequency] completions, and never mid-level.
  Future<void> maybeShowLevelCompleteInterstitial() async {
    _levelCompletionsSinceLastAd++;
    if (_levelCompletionsSinceLastAd < interstitialFrequency) return;
    final ad = _interstitialAd;
    if (ad == null) return;
    _levelCompletionsSinceLastAd = 0;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }

  /// True when there is no loaded rewarded ad to show, i.e. the house-ad
  /// fallback slot should be offered instead (offline, or AdMob failed to
  /// load).
  bool get shouldShowHouseAd => !isRewardedReady;

  /// Opens [houseAdUrl] in the device's browser. Returns false if nothing
  /// on the device can handle the link, instead of throwing.
  Future<bool> openHouseAd() async {
    final uri = Uri.parse(houseAdUrl);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('AdService: could not open house ad: $e');
      return false;
    }
  }
}
