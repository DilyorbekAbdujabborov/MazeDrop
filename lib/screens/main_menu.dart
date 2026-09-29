import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../systems/ad_service.dart';
import '../systems/analytics_service.dart';
import '../systems/audio_manager.dart';
import '../systems/level_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import 'game_screen.dart';
import 'level_select.dart';
import 'settings.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
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

  void _play(BuildContext context) {
    final nextLevel = storage.unlockedCount;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          levelId: nextLevel,
          storage: storage,
          levelManager: levelManager,
          audio: audio,
          analytics: analytics,
          ads: ads,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _Logo(),
                const Spacer(flex: 2),
                GameButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => _play(context),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GameButton(
                      label: 'Levels',
                      filled: false,
                      compact: true,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LevelSelectScreen(
                            storage: storage,
                            levelManager: levelManager,
                            audio: audio,
                            analytics: analytics,
                            ads: ads,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GameButton(
                      label: 'Settings',
                      filled: false,
                      compact: true,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            storage: storage,
                            audio: audio,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Icon(Icons.water_drop, color: AppColors.background, size: 48),
        ),
        const SizedBox(height: 16),
        Text('MazeDrop', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(
          'Guide the drop home',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
