import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_menu.dart';
import 'services/storage_service.dart';
import 'systems/ad_service.dart';
import 'systems/analytics_service.dart';
import 'systems/audio_manager.dart';
import 'systems/level_manager.dart';
import 'theme/app_theme.dart';
import 'widgets/game_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storage = await StorageService.create();
  final audio = AudioManager(storage);
  final analytics = AnalyticsService();
  final ads = AdService();
  final levelManager = LevelManager(storage);

  analytics.logGameStarted();
  unawaited(ads.initialize());
  unawaited(audio.startMusic());
  GameButton.onAnyPress = () => audio.playSfx(SoundEffect.buttonClick);

  runApp(
    MazeDropApp(
      storage: storage,
      levelManager: levelManager,
      audio: audio,
      analytics: analytics,
      ads: ads,
    ),
  );
}

class MazeDropApp extends StatelessWidget {
  const MazeDropApp({
    super.key,
    required this.storage,
    required this.levelManager,
    required this.audio,
    required this.analytics,
    required this.ads,
  });

  final StorageService storage;
  final LevelManager levelManager;
  final AudioManager audio;
  final AnalyticsService analytics;
  final AdService ads;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MazeDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MainMenuScreen(
        storage: storage,
        levelManager: levelManager,
        audio: audio,
        analytics: analytics,
        ads: ads,
      ),
    );
  }
}
