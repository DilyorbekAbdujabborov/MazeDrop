import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/maze_drop_game.dart';
import '../models/level.dart';
import '../models/player_state.dart';
import '../services/storage_service.dart';
import '../systems/ad_service.dart';
import '../systems/analytics_service.dart';
import '../systems/audio_manager.dart';
import '../systems/level_loader.dart';
import '../systems/level_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/life_indicator.dart';
import '../widgets/screen_header.dart';

enum _Overlay { none, paused, levelComplete, gameOver }

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.levelId,
    required this.storage,
    required this.levelManager,
    required this.audio,
    required this.analytics,
    required this.ads,
  });

  final int levelId;
  final StorageService storage;
  final LevelManager levelManager;
  final AudioManager audio;
  final AnalyticsService analytics;
  final AdService ads;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  MazeDropGame? _game;
  Level? _level;
  String? _loadError;
  _Overlay _overlay = _Overlay.none;
  PlayerState? _lastState;
  int _previousLives = 3;
  Offset _dragAccumulator = Offset.zero;
  int _computedStars = 0;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final level = await widget.levelManager.loadLevel(widget.levelId);
      final game = MazeDropGame(
        level: level,
        audio: widget.audio,
        analytics: widget.analytics,
        onStateChanged: _onStateChanged,
        onWin: _onWin,
        onGameOver: _onGameOver,
      );
      widget.analytics.logLevelStarted(widget.levelId);
      if (!mounted) return;
      setState(() {
        _level = level;
        _game = game;
        _previousLives = 3;
      });
    } on LevelLoadException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    }
  }

  void _onStateChanged(PlayerState state) {
    if (state.lives < _previousLives) {
      if (widget.storage.vibrationEnabled) HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
    _previousLives = state.lives;
    if (!mounted) return;
    setState(() => _lastState = state);
  }

  void _onWin(PlayerState state) {
    final level = _level!;
    _computedStars = widget.levelManager.computeStars(
      level,
      moves: state.moves,
      timeSeconds: state.elapsedSeconds,
    );
    widget.levelManager.recordResult(
      level: level,
      moves: state.moves,
      timeSeconds: state.elapsedSeconds,
    );
    widget.ads.maybeShowLevelCompleteInterstitial();
    if (!mounted) return;
    setState(() {
      _lastState = state;
      _overlay = _Overlay.levelComplete;
    });
  }

  void _onGameOver(PlayerState state) {
    if (!mounted) return;
    setState(() {
      _lastState = state;
      _overlay = _Overlay.gameOver;
    });
  }

  void _restart() {
    setState(() {
      _overlay = _Overlay.none;
      _game = null;
      _level = null;
      _lastState = null;
    });
    _load();
  }

  void _nextLevel() {
    if (widget.levelId >= widget.levelManager.totalLevels) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          levelId: widget.levelId + 1,
          storage: widget.storage,
          levelManager: widget.levelManager,
          audio: widget.audio,
          analytics: widget.analytics,
          ads: widget.ads,
        ),
      ),
    );
  }

  void _goHome() => Navigator.of(context).popUntil((route) => route.isFirst);

  void _openHouseAd() {
    widget.analytics.logHouseAdClicked(AdService.houseAdUrl);
    widget.ads.openHouseAd();
  }

  void _togglePause() {
    final game = _game;
    if (game == null) return;
    if (_overlay == _Overlay.paused) {
      game.resumeGame();
      setState(() => _overlay = _Overlay.none);
    } else if (_overlay == _Overlay.none) {
      game.pauseGame();
      setState(() => _overlay = _Overlay.paused);
    }
  }

  Future<void> _continueWithAd(MazeDropGame game) async {
    final earned = await widget.ads.showRewardedContinue(
      onReward: () {
        widget.analytics.logContinueUsed(widget.levelId);
        widget.analytics.logAdWatched('rewarded');
      },
    );
    if (earned && mounted) {
      game.continueWithExtraLife();
      setState(() => _overlay = _Overlay.none);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) => _dragAccumulator += details.delta;

  void _onPanEnd(DragEndDetails details) {
    final dx = _dragAccumulator.dx;
    final dy = _dragAccumulator.dy;
    _dragAccumulator = Offset.zero;
    const threshold = 16.0;
    if (dx.abs() < threshold && dy.abs() < threshold) return;
    if (dx.abs() > dy.abs()) {
      _game?.movePlayer(dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      _game?.movePlayer(dy > 0 ? SwipeDirection.down : SwipeDirection.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _ErrorScreen(message: _loadError!, onBack: () => Navigator.of(context).pop());
    }
    final game = _game;
    final level = _level;
    if (game == null || level == null) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.screenBackground,
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    final state = _lastState ?? game.playerState;

    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Hud(
                    levelId: widget.levelId,
                    lives: state.lives,
                    moves: state.moves,
                    seconds: level.hasTimeLimit ? state.remainingSeconds : state.elapsedSeconds,
                    countdown: level.hasTimeLimit,
                    onPause: _togglePause,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: AnimatedBuilder(
                        animation: _shake,
                        builder: (context, child) {
                          final t = _shake.value;
                          final amp = (1 - t) * 10;
                          final dx = math.sin(t * math.pi * 8) * amp;
                          final dy = math.cos(t * math.pi * 6) * amp * 0.5;
                          return Transform.translate(offset: Offset(dx, dy), child: child);
                        },
                        child: Container(
                          decoration: AppTheme.glassCard(radius: 26),
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: GestureDetector(
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: GameWidget(game: game),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.storage.controlScheme == 'dpad') _DPad(onDirection: game.movePlayer),
                ],
              ),
              if (_overlay == _Overlay.paused)
                _OverlayCard(
                  child: _PauseContent(onResume: _togglePause, onRestart: _restart, onHome: _goHome),
                ),
              if (_overlay == _Overlay.levelComplete)
                _OverlayCard(
                  child: _LevelCompleteContent(
                    stars: _computedStars,
                    moves: state.moves,
                    seconds: state.elapsedSeconds,
                    coins: state.coinsCollected,
                    isLast: widget.levelId >= widget.levelManager.totalLevels,
                    onNext: _nextLevel,
                    onRetry: _restart,
                    onHome: _goHome,
                    onHouseAdTap: _openHouseAd,
                  ),
                ),
              if (_overlay == _Overlay.gameOver)
                _OverlayCard(
                  child: _GameOverContent(
                    canContinue: widget.ads.isRewardedReady,
                    showHouseAd: widget.ads.shouldShowHouseAd,
                    onRestart: _restart,
                    onHome: _goHome,
                    onContinue: () => _continueWithAd(game),
                    onHouseAdTap: _openHouseAd,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------

class _Hud extends StatelessWidget {
  const _Hud({
    required this.levelId,
    required this.lives,
    required this.moves,
    required this.seconds,
    required this.countdown,
    required this.onPause,
  });

  final int levelId;
  final int lives;
  final int moves;
  final int seconds;
  final bool countdown;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final urgent = countdown && seconds <= 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GlassIconButton(icon: Icons.pause_rounded, onTap: onPause),
          const SizedBox(width: 10),
          _HudChip(
            icon: Icons.flag_rounded,
            iconColor: AppColors.accent,
            text: 'Lvl $levelId',
          ),
          const SizedBox(width: 8),
          _HudChip(
            icon: Icons.swipe_rounded,
            iconColor: AppColors.textSecondary,
            text: '$moves',
          ),
          const SizedBox(width: 8),
          _HudChip(
            icon: countdown ? Icons.timer_rounded : Icons.schedule_rounded,
            iconColor: urgent ? AppColors.danger : AppColors.textSecondary,
            text: '${seconds}s',
            highlight: urgent,
          ),
          const Spacer(),
          LifeIndicator(lives: lives),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.mediumAnim,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppTheme.chip(
        fill: highlight ? AppColors.danger.withAlpha(50) : null,
        borderColor: highlight ? AppColors.danger : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: highlight ? AppColors.danger : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  const _DPad({required this.onDirection});

  final void Function(SwipeDirection) onDirection;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, SwipeDirection dir) => Padding(
          padding: const EdgeInsets.all(3),
          child: GlassIconButton(icon: icon, size: 52, onTap: () => onDirection(dir)),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.keyboard_arrow_up_rounded, SwipeDirection.up),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              arrow(Icons.keyboard_arrow_left_rounded, SwipeDirection.left),
              const SizedBox(width: 58),
              arrow(Icons.keyboard_arrow_right_rounded, SwipeDirection.right),
            ],
          ),
          arrow(Icons.keyboard_arrow_down_rounded, SwipeDirection.down),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overlays
// ---------------------------------------------------------------------------

/// Dimmed scrim + a glass card that scales/fades in.
class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppTheme.mediumAnim,
        curve: Curves.easeOutBack,
        builder: (context, t, card) {
          final clamped = t.clamp(0.0, 1.0);
          return Container(
            color: Color.lerp(Colors.transparent, const Color(0xCC08152B), clamped),
            child: Center(
              child: Opacity(
                opacity: clamped,
                child: Transform.scale(scale: 0.85 + 0.15 * t, child: card),
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: AppTheme.glassCard(radius: 28),
          child: child,
        ),
      ),
    );
  }
}

class _PauseContent extends StatelessWidget {
  const _PauseContent({required this.onResume, required this.onRestart, required this.onHome});

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_circle_filled_rounded, color: AppColors.primary, size: 48),
        const SizedBox(height: 10),
        Text('Paused', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        GameButton(label: 'Resume', icon: Icons.play_arrow_rounded, expand: true, onPressed: onResume),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'Restart',
                icon: Icons.refresh_rounded,
                filled: false,
                compact: true,
                expand: true,
                onPressed: onRestart,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                label: 'Home',
                icon: Icons.home_rounded,
                filled: false,
                compact: true,
                expand: true,
                onPressed: onHome,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelCompleteContent extends StatelessWidget {
  const _LevelCompleteContent({
    required this.stars,
    required this.moves,
    required this.seconds,
    required this.coins,
    required this.isLast,
    required this.onNext,
    required this.onRetry,
    required this.onHome,
    required this.onHouseAdTap,
  });

  final int stars;
  final int moves;
  final int seconds;
  final int coins;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback onHouseAdTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('LEVEL COMPLETE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent)),
        const SizedBox(height: 6),
        Text(
          stars == 3 ? 'Flawless!' : (stars == 2 ? 'Nicely done' : 'Made it'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        _StarReveal(stars: stars),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(icon: Icons.swipe_rounded, value: '$moves', label: 'moves'),
            const SizedBox(width: 8),
            _StatChip(icon: Icons.schedule_rounded, value: '${seconds}s', label: 'time'),
            const SizedBox(width: 8),
            _StatChip(icon: Icons.monetization_on_rounded, value: '$coins', label: 'coins', color: AppColors.gold),
          ],
        ),
        const SizedBox(height: 16),
        _HouseAdBanner(onTap: onHouseAdTap),
        const SizedBox(height: 16),
        GameButton(
          label: isLast ? 'Back to levels' : 'Next Level',
          icon: isLast ? Icons.grid_view_rounded : Icons.arrow_forward_rounded,
          expand: true,
          onPressed: onNext,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                filled: false,
                compact: true,
                expand: true,
                onPressed: onRetry,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                label: 'Home',
                icon: Icons.home_rounded,
                filled: false,
                compact: true,
                expand: true,
                onPressed: onHome,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Stars pop in one after another (120 ms apart).
class _StarReveal extends StatelessWidget {
  const _StarReveal({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + i * 120),
          curve: Curves.elasticOut,
          builder: (context, t, child) => Transform.scale(scale: t, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.star_rounded,
              size: i == 1 ? 52 : 42,
              color: earned ? AppColors.gold : AppColors.textSecondary.withAlpha(70),
              shadows: earned ? const [Shadow(color: Color(0x99FFC64B), blurRadius: 18)] : null,
            ),
          ),
        );
      }),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppTheme.chip(),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

class _GameOverContent extends StatelessWidget {
  const _GameOverContent({
    required this.canContinue,
    required this.showHouseAd,
    required this.onRestart,
    required this.onHome,
    required this.onContinue,
    required this.onHouseAdTap,
  });

  final bool canContinue;
  final bool showHouseAd;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onContinue;
  final VoidCallback onHouseAdTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.water_drop_outlined, color: AppColors.danger, size: 48),
        const SizedBox(height: 10),
        Text('Out of drops', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('The maze got you this time.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 22),
        if (canContinue) ...[
          GameButton(
            label: 'Continue',
            subtitle: 'Watch an ad for +1 life',
            icon: Icons.play_circle_fill_rounded,
            expand: true,
            onPressed: onContinue,
          ),
          const SizedBox(height: 10),
        ] else if (showHouseAd) ...[
          _HouseAdBanner(onTap: onHouseAdTap),
          const SizedBox(height: 12),
        ],
        GameButton(
          label: 'Restart Level',
          icon: Icons.refresh_rounded,
          filled: !canContinue,
          expand: true,
          onPressed: onRestart,
        ),
        const SizedBox(height: 10),
        GameButton(
          label: 'Main Menu',
          icon: Icons.home_rounded,
          filled: false,
          compact: true,
          expand: true,
          onPressed: onHome,
        ),
      ],
    );
  }
}

/// A cross-promo banner shown on Level Complete, and as a fallback on Game
/// Over when no real rewarded ad is available (e.g. offline). Deliberately
/// does not grant any in-game reward for tapping it -- there is no
/// ad-network verification behind a plain link, so it is labeled
/// "Sponsored" rather than disguised as the real continue-ad flow.
class _HouseAdBanner extends StatelessWidget {
  const _HouseAdBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(150),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withAlpha(90)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.accent.withAlpha(40),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SPONSORED', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
                  Text(
                    'Check out Cefrify',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassCard(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  'This level could not be loaded.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GameButton(label: 'Back', expand: true, onPressed: onBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
