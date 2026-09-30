import 'dart:math' as math;

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

class MainMenuScreen extends StatefulWidget {
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

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // progress may have changed
  }

  void _play() {
    _push(
      GameScreen(
        levelId: widget.levelManager.nextLevelToPlay,
        storage: widget.storage,
        levelManager: widget.levelManager,
        audio: widget.audio,
        analytics: widget.analytics,
        ads: widget.ads,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.levelManager;
    final completed = manager.completedCount;
    final stars = manager.totalStars;
    final next = manager.nextLevelToPlay;

    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (_, _) => CustomPaint(painter: _DropletFieldPainter(_ambient.value)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    _Logo(animation: _ambient),
                    const SizedBox(height: 28),
                    _ProgressChips(completed: completed, total: manager.totalLevels, stars: stars),
                    const Spacer(flex: 3),
                    GameButton(
                      label: 'PLAY',
                      subtitle: completed == 0 ? 'Start your journey' : 'Level $next',
                      icon: Icons.play_arrow_rounded,
                      expand: true,
                      onPressed: _play,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GameButton(
                            label: 'Levels',
                            icon: Icons.grid_view_rounded,
                            filled: false,
                            compact: true,
                            expand: true,
                            onPressed: () => _push(
                              LevelSelectScreen(
                                storage: widget.storage,
                                levelManager: widget.levelManager,
                                audio: widget.audio,
                                analytics: widget.analytics,
                                ads: widget.ads,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GameButton(
                            label: 'Settings',
                            icon: Icons.tune_rounded,
                            filled: false,
                            compact: true,
                            expand: true,
                            onPressed: () => _push(
                              SettingsScreen(storage: widget.storage, audio: widget.audio),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // gentle bob: 3 full cycles over the ambient loop
            final bob = math.sin(animation.value * math.pi * 2 * 3) * 6;
            return Transform.translate(offset: Offset(0, bob), child: child);
          },
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withAlpha(120), blurRadius: 40, spreadRadius: 4),
              ],
            ),
            child: const Icon(Icons.water_drop_rounded, color: AppColors.background, size: 64),
          ),
        ),
        const SizedBox(height: 22),
        ShaderMask(
          shaderCallback: (rect) => AppTheme.titleGradient.createShader(rect),
          child: Text(
            'MazeDrop',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text('Guide the drop home', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ProgressChips extends StatelessWidget {
  const _ProgressChips({required this.completed, required this.total, required this.stars});
  final int completed;
  final int total;
  final int stars;

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, Color color, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: AppTheme.chip(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(Icons.flag_rounded, AppColors.accent, '$completed / $total levels'),
        const SizedBox(width: 10),
        chip(Icons.star_rounded, AppColors.gold, '$stars / ${total * 3}'),
      ],
    );
  }
}

/// Slowly rising translucent droplets behind the menu.
class _DropletFieldPainter extends CustomPainter {
  _DropletFieldPainter(this.t);
  final double t;

  static final List<_Droplet> _drops = List.generate(16, (i) {
    final r = math.Random(i * 31 + 7);
    return _Droplet(
      x: r.nextDouble(),
      phase: r.nextDouble(),
      radius: 6 + r.nextDouble() * 14,
      speed: 0.6 + r.nextDouble() * 0.8,
      alpha: 18 + r.nextInt(30),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _drops) {
      final progress = (d.phase + t * d.speed) % 1.0;
      final y = size.height * (1.1 - progress * 1.2);
      final x = size.width * d.x + math.sin(progress * math.pi * 4) * 12;
      final paint = Paint()..color = AppColors.primary.withAlpha(d.alpha);
      canvas.drawCircle(Offset(x, y), d.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DropletFieldPainter old) => old.t != t;
}

class _Droplet {
  const _Droplet({
    required this.x,
    required this.phase,
    required this.radius,
    required this.speed,
    required this.alpha,
  });
  final double x, phase, radius, speed;
  final int alpha;
}
