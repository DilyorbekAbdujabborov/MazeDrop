import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';

import '../models/level.dart';
import '../models/level_object.dart';
import '../models/player_state.dart';
import '../systems/analytics_service.dart';
import '../systems/audio_manager.dart';
import '../theme/app_theme.dart';
import 'components/coin.dart';
import 'components/door.dart';
import 'components/exit.dart';
import 'components/key.dart';
import 'components/player.dart';
import 'components/teleport.dart';
import 'components/trap.dart';
import 'components/wall.dart';

enum SwipeDirection { up, down, left, right }

class _TileEntry {
  _TileEntry(this.component, this.gridPos);
  final PositionComponent component;
  final GridPos gridPos;
}

/// A moving hazard rendered as a spinning spiked disc.
class _ObstacleComponent extends PositionComponent {
  _ObstacleComponent({required super.position, required super.size}) {
    add(RotateEffect.by(6.28318, EffectController(duration: 1.6, infinite: true)));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final paint = Paint()..color = AppColors.danger;
    canvas.drawCircle(center, size.x * 0.32, paint);
    final spike = Paint()..color = AppColors.danger;
    for (var i = 0; i < 6; i++) {
      final angle = i * (math.pi / 3);
      final dx = math.cos(angle) * size.x * 0.42;
      final dy = math.sin(angle) * size.y * 0.42;
      canvas.drawCircle(center.translate(dx, dy), size.x * 0.06, spike);
    }
  }
}

class _ObstacleEntry {
  _ObstacleEntry(this.data, this.component);
  final MovingObstacle data;
  final _ObstacleComponent component;
}

/// The Flame game running a single MazeDrop level: grid layout, tile
/// components, swipe-driven movement, and all gameplay resolution
/// (traps, keys/doors, teleports, coins, moving hazards, win/lose).
class MazeDropGame extends FlameGame {
  MazeDropGame({
    required this.level,
    required this.audio,
    required this.analytics,
    required this.onStateChanged,
    required this.onWin,
    required this.onGameOver,
  });

  final Level level;
  final AudioManager audio;
  final AnalyticsService analytics;
  final void Function(PlayerState state) onStateChanged;
  final void Function(PlayerState state) onWin;
  final void Function(PlayerState state) onGameOver;

  late final PlayerState playerState = PlayerState(position: level.player);
  late final PlayerComponent _playerComponent;

  double tileSize = 32;
  Vector2 boardOrigin = Vector2.zero();
  int elapsedMs = 0;

  final List<_TileEntry> _tileEntries = [];
  final Map<GridPos, KeyComponent> _keyComponents = {};
  final Map<GridPos, DoorComponent> _doorComponents = {};
  final Map<GridPos, CoinComponent> _coinComponents = {};
  final List<_ObstacleEntry> _obstacleEntries = [];
  double _obstacleCooldownMs = 0;

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    _layout(size);
    await _buildBoard();
    audio.startMusic();
    onStateChanged(playerState);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    _layout(size);
    _repositionAll();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (playerState.status == RunStatus.playing) {
      elapsedMs += (dt * 1000).round();
      playerState.elapsedMs = elapsedMs;
    }
    _updateObstacles(dt);
  }

  void _layout(Vector2 canvasSize) {
    final cols = level.width;
    final rows = level.height;
    if (canvasSize.x <= 0 || canvasSize.y <= 0) return;
    tileSize = math.min(canvasSize.x / cols, canvasSize.y / rows);
    final boardW = tileSize * cols;
    final boardH = tileSize * rows;
    boardOrigin = Vector2(
      (canvasSize.x - boardW) / 2,
      (canvasSize.y - boardH) / 2,
    );
  }

  Vector2 cellTopLeft(GridPos p) => Vector2(
        boardOrigin.x + p.x * tileSize,
        boardOrigin.y + p.y * tileSize,
      );

  Vector2 get _tileVector => Vector2.all(tileSize);

  void _repositionAll() {
    for (final entry in _tileEntries) {
      entry.component.position = cellTopLeft(entry.gridPos);
      entry.component.size = _tileVector;
    }
    _playerComponent.position = cellTopLeft(playerState.position);
    _playerComponent.size = _tileVector;
  }

  Future<void> _buildBoard() async {
    for (final wall in level.walls) {
      final c = WallComponent(position: cellTopLeft(wall), size: _tileVector);
      _tileEntries.add(_TileEntry(c, wall));
      add(c);
    }
    for (final mw in level.movingWalls) {
      final c = MovingWallComponent(
        data: mw,
        position: cellTopLeft(mw.pos),
        size: _tileVector,
      );
      _tileEntries.add(_TileEntry(c, mw.pos));
      add(c);
    }
    for (final trap in level.traps) {
      final c = TrapComponent(
        data: trap,
        position: cellTopLeft(trap.pos),
        size: _tileVector,
      );
      _tileEntries.add(_TileEntry(c, trap.pos));
      add(c);
    }
    for (final coin in level.coins) {
      final c = CoinComponent(position: cellTopLeft(coin), size: _tileVector);
      _coinComponents[coin] = c;
      _tileEntries.add(_TileEntry(c, coin));
      add(c);
    }
    for (final key in level.keys) {
      final c = KeyComponent(
        data: key,
        position: cellTopLeft(key.pos),
        size: _tileVector,
      );
      _keyComponents[key.pos] = c;
      _tileEntries.add(_TileEntry(c, key.pos));
      add(c);
    }
    for (final door in level.doors) {
      final c = DoorComponent(
        data: door,
        position: cellTopLeft(door.pos),
        size: _tileVector,
      );
      _doorComponents[door.pos] = c;
      _tileEntries.add(_TileEntry(c, door.pos));
      add(c);
    }
    for (final tp in level.teleports) {
      final c = TeleportComponent(
        data: tp,
        position: cellTopLeft(tp.pos),
        size: _tileVector,
      );
      _tileEntries.add(_TileEntry(c, tp.pos));
      add(c);
    }
    for (final obstacle in level.movingObstacles) {
      final c = _ObstacleComponent(
        position: cellTopLeft(obstacle.path.first),
        size: _tileVector,
      );
      _obstacleEntries.add(_ObstacleEntry(obstacle, c));
      add(c);
    }

    final exitComponent =
        ExitComponent(position: cellTopLeft(level.exit), size: _tileVector);
    _tileEntries.add(_TileEntry(exitComponent, level.exit));
    add(exitComponent);

    _playerComponent = PlayerComponent(
      position: cellTopLeft(level.player),
      size: _tileVector,
    );
    add(_playerComponent);
    _playerComponent.playSpawnAnimation();
  }

  void _updateObstacles(double dt) {
    if (_obstacleCooldownMs > 0) {
      _obstacleCooldownMs -= dt * 1000;
    }
    for (final entry in _obstacleEntries) {
      final cell = entry.data.positionAt(elapsedMs);
      entry.component.position = cellTopLeft(cell);
      entry.component.size = _tileVector;
      if (_obstacleCooldownMs <= 0 &&
          playerState.status == RunStatus.playing &&
          cell == playerState.position) {
        _obstacleCooldownMs = 800;
        _handleHazardHit();
      }
    }
  }

  // --- Input ------------------------------------------------------------

  void movePlayer(SwipeDirection dir) {
    if (playerState.status != RunStatus.playing) return;
    var dx = 0, dy = 0;
    switch (dir) {
      case SwipeDirection.up:
        dy = -1;
      case SwipeDirection.down:
        dy = 1;
      case SwipeDirection.left:
        dx = -1;
      case SwipeDirection.right:
        dx = 1;
    }
    final target = GridPos(playerState.position.x + dx, playerState.position.y + dy);
    if (!_canEnter(target)) return;

    playerState.moves++;
    playerState.position = target;
    audio.playSfx(SoundEffect.move);
    onStateChanged(playerState);
    _playerComponent.animateMoveTo(
      cellTopLeft(target),
      onComplete: () => _resolveTile(target),
    );
  }

  bool _canEnter(GridPos target) {
    if (!level.inBounds(target)) return false;
    if (level.walls.contains(target)) return false;
    for (final mw in level.movingWalls) {
      if (mw.pos == target && !mw.isOpenAt(elapsedMs)) return false;
    }
    final door = _doorComponents[target];
    if (door != null && !door.isOpen) return false;
    return true;
  }

  void _resolveTile(GridPos pos) {
    if (playerState.status != RunStatus.playing) return;

    final coin = _coinComponents[pos];
    if (coin != null && !coin.collected) {
      coin.collected = true;
      playerState.coinsCollected++;
      audio.playSfx(SoundEffect.collectCoin);
      analytics.logCoinCollected(level.id);
    }

    final key = _keyComponents[pos];
    if (key != null && !key.collected && !playerState.hasKey(key.data.id)) {
      key.collected = true;
      playerState.collectKey(key.data.id);
      audio.playSfx(SoundEffect.collectKey);
      analytics.logKeyCollected(level.id);
      _unlockMatchingDoors(key.data.id);
    }

    for (final trap in level.traps) {
      if (trap.pos == pos && trap.isDangerousAt(elapsedMs)) {
        _handleHazardHit();
        return;
      }
    }

    for (final tp in level.teleports) {
      if (tp.pos == pos) {
        TeleportObject? partner;
        for (final other in level.teleports) {
          if (other.pairId == tp.pairId && other.pos != pos) {
            partner = other;
            break;
          }
        }
        if (partner != null) {
          playerState.position = partner.pos;
          _playerComponent.position = cellTopLeft(partner.pos);
          audio.playSfx(SoundEffect.teleport);
        }
        break;
      }
    }

    if (playerState.position == level.exit) {
      _handleWin();
      return;
    }

    onStateChanged(playerState);
  }

  void _unlockMatchingDoors(String keyId) {
    var unlockedAny = false;
    for (final door in _doorComponents.values) {
      if (door.data.keyId == keyId) {
        door.isOpen = true;
        unlockedAny = true;
      }
    }
    if (unlockedAny) audio.playSfx(SoundEffect.unlockDoor);
  }

  void _handleHazardHit() {
    if (playerState.status != RunStatus.playing) return;
    playerState.lives--;
    audio.playSfx(SoundEffect.trap);
    onStateChanged(playerState);

    if (playerState.lives <= 0) {
      playerState.status = RunStatus.dead;
      analytics.logLevelFailed(levelId: level.id, deaths: 1);
      _playerComponent.playDeathAnimation(
        onComplete: () => onGameOver(playerState),
      );
    } else {
      playerState.status = RunStatus.paused;
      _playerComponent.playDeathAnimation(
        onComplete: () {
          playerState.position = level.player;
          _playerComponent.position = cellTopLeft(level.player);
          _playerComponent.playSpawnAnimation();
          playerState.status = RunStatus.playing;
          onStateChanged(playerState);
        },
      );
    }
  }

  void _handleWin() {
    playerState.status = RunStatus.won;
    audio.playSfx(SoundEffect.levelComplete);
    analytics.logLevelCompleted(
      levelId: level.id,
      timeSeconds: playerState.elapsedSeconds,
      moves: playerState.moves,
    );
    onWin(playerState);
  }

  /// Grants one extra life and resumes play from the current position,
  /// used by the rewarded "continue after death" ad.
  void continueWithExtraLife() {
    if (playerState.status != RunStatus.dead) return;
    playerState.lives = 1;
    playerState.status = RunStatus.playing;
    onStateChanged(playerState);
  }

  void pauseGame() {
    if (playerState.status == RunStatus.playing) {
      playerState.status = RunStatus.paused;
      pauseEngine();
    }
  }

  void resumeGame() {
    if (playerState.status == RunStatus.paused) {
      playerState.status = RunStatus.playing;
      resumeEngine();
    }
  }
}
