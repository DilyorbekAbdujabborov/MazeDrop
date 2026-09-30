import 'package:flutter/foundation.dart';

/// Analytics architecture, ready to be backed by Firebase Analytics.
///
/// No `firebase_analytics` dependency or `google-services.json` is wired
/// up in this MVP (there is no Firebase project to point it at yet), so
/// events are only logged locally in debug builds. To go live: add the
/// `firebase_analytics` package, drop in `google-services.json`, and
/// replace the body of [_send] with `FirebaseAnalytics.instance.logEvent`.
class AnalyticsService {
  static const gameStarted = 'game_started';
  static const levelStarted = 'level_started';
  static const levelCompleted = 'level_completed';
  static const levelFailed = 'level_failed';
  static const adWatched = 'ad_watched';
  static const continueUsed = 'continue_used';
  static const coinCollected = 'coin_collected';
  static const keyCollected = 'key_collected';
  static const houseAdClicked = 'house_ad_clicked';

  void logGameStarted() => _send(gameStarted);

  void logLevelStarted(int levelId) =>
      _send(levelStarted, {'level_id': levelId});

  void logLevelCompleted({
    required int levelId,
    required int timeSeconds,
    required int moves,
  }) =>
      _send(levelCompleted, {
        'level_id': levelId,
        'time': timeSeconds,
        'moves': moves,
      });

  void logLevelFailed({
    required int levelId,
    required int deaths,
  }) =>
      _send(levelFailed, {'level_id': levelId, 'deaths': deaths});

  void logAdWatched(String adType) => _send(adWatched, {'ad_type': adType});

  void logContinueUsed(int levelId) =>
      _send(continueUsed, {'level_id': levelId});

  void logCoinCollected(int levelId) =>
      _send(coinCollected, {'level_id': levelId});

  void logKeyCollected(int levelId) =>
      _send(keyCollected, {'level_id': levelId});

  void logHouseAdClicked(String destinationUrl) =>
      _send(houseAdClicked, {'url': destinationUrl});

  void _send(String event, [Map<String, Object?>? params]) {
    if (kDebugMode) {
      debugPrint('Analytics: $event ${params ?? const {}}');
    }
  }
}
