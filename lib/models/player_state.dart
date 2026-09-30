import 'level_object.dart';

enum RunStatus { playing, won, dead, paused }

/// Mutable state for the current level attempt. Owned by the game and read
/// by the HUD/overlays.
class PlayerState {
  GridPos position;
  int lives;
  int moves;
  int elapsedMs;
  /// Milliseconds left on the level countdown; 0 when the level has no limit.
  int remainingMs;
  int coinsCollected;
  RunStatus status;
  final Set<String> collectedKeyIds;

  PlayerState({
    required this.position,
    this.lives = 3,
    this.moves = 0,
    this.elapsedMs = 0,
    this.remainingMs = 0,
    this.coinsCollected = 0,
    this.status = RunStatus.playing,
    Set<String>? collectedKeyIds,
  }) : collectedKeyIds = collectedKeyIds ?? <String>{};

  bool hasKey(String id) => collectedKeyIds.contains(id);

  void collectKey(String id) => collectedKeyIds.add(id);

  int get elapsedSeconds => elapsedMs ~/ 1000;

  /// Seconds left, rounded up so the HUD never shows 0 while time remains.
  int get remainingSeconds => (remainingMs + 999) ~/ 1000;

  bool get isAlive => lives > 0;
}
