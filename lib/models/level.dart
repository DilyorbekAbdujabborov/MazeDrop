import 'level_object.dart';

/// Immutable description of a single maze level, parsed from
/// `assets/levels/level_XX.json`.
class Level {
  final int id;
  final int width;
  final int height;
  final GridPos player;
  final GridPos exit;
  final Set<GridPos> walls;
  final List<TrapObject> traps;
  final List<KeyObject> keys;
  final List<DoorObject> doors;
  final List<TeleportObject> teleports;
  final Set<GridPos> coins;
  final List<MovingObstacle> movingObstacles;
  final List<MovingWall> movingWalls;
  final int parMoves;
  final int parTimeSeconds;

  /// Countdown budget for the level; running out costs a life. 0 = no limit.
  final int timeLimitSeconds;

  const Level({
    required this.id,
    required this.width,
    required this.height,
    required this.player,
    required this.exit,
    required this.walls,
    required this.traps,
    required this.keys,
    required this.doors,
    required this.teleports,
    required this.coins,
    required this.movingObstacles,
    required this.movingWalls,
    required this.parMoves,
    required this.parTimeSeconds,
    this.timeLimitSeconds = 0,
  });

  bool get hasTimeLimit => timeLimitSeconds > 0;

  factory Level.fromJson(Map<String, dynamic> json) {
    try {
      final width = _asInt(json['width']);
      final height = _asInt(json['height']);
      if (width <= 0 || height <= 0) {
        throw const FormatException('Level width/height must be positive');
      }

      final walls = _list(json['walls'])
          .map((e) => GridPos.fromJson(e as Map<String, dynamic>))
          .toSet();
      final coins = _list(json['coins'])
          .map((e) => GridPos.fromJson(e as Map<String, dynamic>))
          .toSet();
      final traps = _list(json['traps'])
          .map((e) => TrapObject.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      final keys = _list(json['keys'])
          .map((e) => KeyObject.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      final doors = _list(json['doors'])
          .map((e) => DoorObject.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      final teleports = _list(json['teleports'])
          .map((e) => TeleportObject.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      final movingObstacles = _list(json['movingObstacles'])
          .map((e) => MovingObstacle.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      final movingWalls = _list(json['movingWalls'])
          .map((e) => MovingWall.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);

      return Level(
        id: _asInt(json['id']),
        width: width,
        height: height,
        player: GridPos.fromJson(json['player'] as Map<String, dynamic>),
        exit: GridPos.fromJson(json['exit'] as Map<String, dynamic>),
        walls: walls,
        traps: traps,
        keys: keys,
        doors: doors,
        teleports: teleports,
        coins: coins,
        movingObstacles: movingObstacles,
        movingWalls: movingWalls,
        parMoves: (json['parMoves'] as num?)?.toInt() ?? 0,
        parTimeSeconds: (json['parTimeSeconds'] as num?)?.toInt() ?? 0,
        timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 0,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Malformed level JSON: $e');
    }
  }

  bool inBounds(GridPos p) =>
      p.x >= 0 && p.y >= 0 && p.x < width && p.y < height;

  static List<dynamic> _list(dynamic value) =>
      value == null ? const [] : value as List<dynamic>;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Expected integer value in level JSON');
  }
}
