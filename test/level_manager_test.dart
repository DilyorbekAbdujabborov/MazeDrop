import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazedrop/models/level.dart';
import 'package:mazedrop/models/level_object.dart';
import 'package:mazedrop/services/storage_service.dart';
import 'package:mazedrop/systems/level_manager.dart';

Level _levelWithPar() => Level(
      id: 1,
      width: 3,
      height: 3,
      player: const GridPos(0, 0),
      exit: const GridPos(2, 2),
      walls: const {},
      traps: const [],
      keys: const [],
      doors: const [],
      teleports: const [],
      coins: const {},
      movingObstacles: const [],
      movingWalls: const [],
      parMoves: 10,
      parTimeSeconds: 20,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('within par earns 3 stars', () async {
    final storage = await StorageService.create();
    final manager = LevelManager(storage);
    final level = _levelWithPar();
    expect(manager.computeStars(level, moves: 10, timeSeconds: 20), 3);
  });

  test('within 1.5x par earns 2 stars', () async {
    final storage = await StorageService.create();
    final manager = LevelManager(storage);
    final level = _levelWithPar();
    expect(manager.computeStars(level, moves: 14, timeSeconds: 20), 2);
  });

  test('far over par earns 1 star', () async {
    final storage = await StorageService.create();
    final manager = LevelManager(storage);
    final level = _levelWithPar();
    expect(manager.computeStars(level, moves: 100, timeSeconds: 100), 1);
  });

  test('a level with no par always earns 3 stars on completion', () async {
    final storage = await StorageService.create();
    final manager = LevelManager(storage);
    final level = Level(
      id: 2,
      width: 3,
      height: 3,
      player: const GridPos(0, 0),
      exit: const GridPos(2, 2),
      walls: const {},
      traps: const [],
      keys: const [],
      doors: const [],
      teleports: const [],
      coins: const {},
      movingObstacles: const [],
      movingWalls: const [],
      parMoves: 0,
      parTimeSeconds: 0,
    );
    expect(manager.computeStars(level, moves: 999, timeSeconds: 999), 3);
  });
}
