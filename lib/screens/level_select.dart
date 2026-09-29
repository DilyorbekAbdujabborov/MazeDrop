import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../systems/ad_service.dart';
import '../systems/analytics_service.dart';
import '../systems/audio_manager.dart';
import '../systems/level_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/level_card.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({
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
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Future<void> _openLevel(int levelId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          levelId: levelId,
          storage: widget.storage,
          levelManager: widget.levelManager,
          audio: widget.audio,
          analytics: widget.analytics,
          ads: widget.ads,
        ),
      ),
    );
    setState(() {}); // refresh unlock/star state after returning.
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.levelManager.totalLevels;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Levels'),
      ),
      body: Container(
        decoration: AppTheme.screenBackground,
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: total,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final levelId = index + 1;
            return LevelCard(
              levelId: levelId,
              unlocked: widget.levelManager.isUnlocked(levelId),
              stars: widget.levelManager.starsFor(levelId),
              onTap: () => _openLevel(levelId),
            );
          },
        ),
      ),
    );
  }
}
