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

class _GameScreenState extends State<GameScreen> {
  MazeDropGame? _game;
  Level? _level;
  String? _loadError;
  _Overlay _overlay = _Overlay.none;
  PlayerState? _lastState;
  int _previousLives = 3;
  Offset _dragAccumulator = Offset.zero;
  int _computedStars = 0;

  @override
  void initState() {
    super.initState();
    _load();
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
    if (state.lives < _previousLives && widget.storage.vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    _previousLives = state.lives;
    if (!mounted) return;
    setState(() => _lastState = state);
  }

  void _onWin(PlayerState state) {
    _computedStars = widget.levelManager.computeStars(
      _level!,
      moves: state.moves,
      timeSeconds: state.elapsedSeconds,
    );
    widget.levelManager.recordResult(
      level: _level!,
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

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
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

  void _onPanUpdate(DragUpdateDetails details) {
    _dragAccumulator += details.delta;
  }

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
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final state = _lastState ?? game.playerState;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Hud(
                  levelId: widget.levelId,
                  lives: state.lives,
                  moves: state.moves,
                  seconds: state.elapsedSeconds,
                  onPause: _togglePause,
                ),
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: GameWidget(game: game),
                  ),
                ),
                if (widget.storage.controlScheme == 'dpad')
                  _DPad(onDirection: game.movePlayer),
              ],
            ),
            if (_overlay == _Overlay.paused)
              _PauseOverlay(
                onResume: _togglePause,
                onRestart: _restart,
                onHome: _goHome,
              ),
            if (_overlay == _Overlay.levelComplete)
              _LevelCompleteOverlay(
                stars: _computedStars,
                moves: state.moves,
                seconds: state.elapsedSeconds,
                coins: state.coinsCollected,
                onNext: _nextLevel,
                onRetry: _restart,
                onHome: _goHome,
              ),
            if (_overlay == _Overlay.gameOver)
              _GameOverOverlay(
                canContinue: widget.ads.isRewardedReady,
                onRestart: _restart,
                onHome: _goHome,
                onContinue: () async {
                  final earned = await widget.ads.showRewardedContinue(
                    onReward: () {
                      widget.analytics.logContinueUsed(widget.levelId);
                      widget.analytics.logAdWatched('rewarded');
                    },
                  );
                  if (earned) {
                    game.continueWithExtraLife();
                    setState(() => _overlay = _Overlay.none);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.levelId,
    required this.lives,
    required this.moves,
    required this.seconds,
    required this.onPause,
  });

  final int levelId;
  final int lives;
  final int moves;
  final int seconds;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause_circle, color: AppColors.textPrimary),
          ),
          Text('Level $levelId', style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          Text('$moves moves', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 12),
          Text('${seconds}s', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 12),
          LifeIndicator(lives: lives),
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
    Widget arrow(IconData icon, SwipeDirection dir) => IconButton(
          onPressed: () => onDirection(dir),
          icon: Icon(icon, color: AppColors.textPrimary, size: 32),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          arrow(Icons.keyboard_arrow_up, SwipeDirection.up),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              arrow(Icons.keyboard_arrow_left, SwipeDirection.left),
              const SizedBox(width: 48),
              arrow(Icons.keyboard_arrow_right, SwipeDirection.right),
            ],
          ),
          arrow(Icons.keyboard_arrow_down, SwipeDirection.down),
        ],
      ),
    );
  }
}

class _OverlayScrim extends StatelessWidget {
  const _OverlayScrim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xCC0B1D3A),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _OverlayScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Paused', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          GameButton(label: 'Resume', onPressed: onResume),
          const SizedBox(height: 12),
          GameButton(label: 'Restart', filled: false, onPressed: onRestart),
          const SizedBox(height: 12),
          GameButton(label: 'Home', filled: false, onPressed: onHome),
        ],
      ),
    );
  }
}

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({
    required this.stars,
    required this.moves,
    required this.seconds,
    required this.coins,
    required this.onNext,
    required this.onRetry,
    required this.onHome,
  });

  final int stars;
  final int moves;
  final int seconds;
  final int coins;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _OverlayScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('LEVEL COMPLETE!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Icon(
                Icons.star,
                size: 32,
                color: i < stars ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('$moves moves  •  ${seconds}s  •  $coins coins',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          GameButton(label: 'Next Level', onPressed: onNext),
          const SizedBox(height: 12),
          GameButton(label: 'Retry', filled: false, onPressed: onRetry),
          const SizedBox(height: 12),
          GameButton(label: 'Home', filled: false, onPressed: onHome),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.canContinue,
    required this.onRestart,
    required this.onHome,
    required this.onContinue,
  });

  final bool canContinue;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _OverlayScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Game Over', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          if (canContinue) ...[
            GameButton(
              label: 'Continue (Watch Ad)',
              icon: Icons.play_circle,
              onPressed: onContinue,
            ),
            const SizedBox(height: 12),
          ],
          GameButton(label: 'Restart Level', filled: !canContinue, onPressed: onRestart),
          const SizedBox(height: 12),
          GameButton(label: 'Main Menu', filled: false, onPressed: onHome),
        ],
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
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              const Text(
                'This level could not be loaded.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GameButton(label: 'Back', onPressed: onBack),
            ],
          ),
        ),
      ),
    );
  }
}
