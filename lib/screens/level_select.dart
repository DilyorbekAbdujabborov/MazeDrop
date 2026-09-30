import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../systems/ad_service.dart';
import '../systems/analytics_service.dart';
import '../systems/audio_manager.dart';
import '../systems/level_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/level_card.dart';
import '../widgets/screen_header.dart';
import 'game_screen.dart';

const _chapters = <String>[
  'First Drops',
  'Keys & Doors',
  'Spikes & Saws',
  'Portals',
  'Against the Clock',
  'Mastery',
];
const _levelsPerChapter = 5;

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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.levelManager;
    final current = manager.nextLevelToPlay;
    final chapterCount = (manager.totalLevels / _levelsPerChapter).ceil();

    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Levels',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: AppTheme.chip(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${manager.totalStars}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  itemCount: chapterCount,
                  itemBuilder: (context, chapter) {
                    final first = chapter * _levelsPerChapter + 1;
                    final last = (first + _levelsPerChapter - 1).clamp(1, manager.totalLevels);
                    final chapterUnlocked = manager.isUnlocked(first);
                    final chapterStars = List.generate(last - first + 1, (i) => manager.starsFor(first + i))
                        .fold(0, (a, b) => a + b);
                    return _ChapterSection(
                      title: chapter < _chapters.length ? _chapters[chapter] : 'Chapter ${chapter + 1}',
                      unlocked: chapterUnlocked,
                      stars: chapterStars,
                      maxStars: (last - first + 1) * 3,
                      child: GridView.count(
                        crossAxisCount: _levelsPerChapter,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: List.generate(last - first + 1, (i) {
                          final id = first + i;
                          return LevelCard(
                            levelId: id,
                            unlocked: manager.isUnlocked(id),
                            stars: manager.starsFor(id),
                            isCurrent: id == current && !manager.isCompleted(id),
                            onTap: () => _openLevel(id),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({
    required this.title,
    required this.unlocked,
    required this.stars,
    required this.maxStars,
    required this.child,
  });

  final String title;
  final bool unlocked;
  final int stars;
  final int maxStars;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassCard(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Icon(
                    unlocked ? Icons.star_rounded : Icons.lock_rounded,
                    size: 15,
                    color: unlocked ? AppColors.gold : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unlocked ? '$stars / $maxStars' : 'Locked',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
