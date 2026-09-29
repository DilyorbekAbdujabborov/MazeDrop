import '../models/level.dart';
import '../services/storage_service.dart';
import 'level_loader.dart';

/// High-level facade the UI talks to: level unlocking, star/best-score
/// bookkeeping, and level loading, all backed by [StorageService].
class LevelManager {
  LevelManager(this._storage, {this._loader = const LevelLoader()});

  final StorageService _storage;
  final LevelLoader _loader;

  int get totalLevels => StorageService.totalLevels;

  bool isUnlocked(int levelId) => _storage.isLevelUnlocked(levelId);
  bool isCompleted(int levelId) => _storage.isLevelCompleted(levelId);
  int starsFor(int levelId) => _storage.starsFor(levelId);
  int? bestMovesFor(int levelId) => _storage.bestMovesFor(levelId);
  int? bestTimeFor(int levelId) => _storage.bestTimeFor(levelId);

  Future<Level> loadLevel(int levelId) => _loader.load(levelId);

  /// 1-3 stars based on how close the run was to the level's par
  /// move/time budget. Levels without a par (parMoves/parTimeSeconds == 0)
  /// always award 3 stars for a bare completion.
  int computeStars(Level level, {required int moves, required int timeSeconds}) {
    final hasPar = level.parMoves > 0 && level.parTimeSeconds > 0;
    if (!hasPar) return 3;
    final withinPar = moves <= level.parMoves && timeSeconds <= level.parTimeSeconds;
    if (withinPar) return 3;
    final withinStretch =
        moves <= (level.parMoves * 1.5).round() ||
            timeSeconds <= (level.parTimeSeconds * 1.5).round();
    return withinStretch ? 2 : 1;
  }

  Future<void> recordResult({
    required Level level,
    required int moves,
    required int timeSeconds,
  }) async {
    final stars = computeStars(level, moves: moves, timeSeconds: timeSeconds);
    await _storage.recordLevelResult(
      levelId: level.id,
      stars: stars,
      timeSeconds: timeSeconds,
      moves: moves,
    );
  }
}
