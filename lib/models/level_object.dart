/// Integer grid coordinate shared by every placeable object in a level.
class GridPos {
  final int x;
  final int y;

  const GridPos(this.x, this.y);

  factory GridPos.fromJson(Map<String, dynamic> json) {
    return GridPos(
      _asInt(json['x']),
      _asInt(json['y']),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Expected integer grid coordinate');
  }

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}

/// A key that can be picked up to unlock a [DoorObject] sharing the same [id].
class KeyObject {
  final GridPos pos;
  final String id;

  const KeyObject(this.pos, this.id);

  factory KeyObject.fromJson(Map<String, dynamic> json) {
    return KeyObject(
      GridPos.fromJson(json),
      json['id']?.toString() ?? 'key_${json['x']}_${json['y']}',
    );
  }
}

/// A locked door that opens once the matching key ([keyId]) is collected.
class DoorObject {
  final GridPos pos;
  final String keyId;

  const DoorObject(this.pos, this.keyId);

  factory DoorObject.fromJson(Map<String, dynamic> json) {
    return DoorObject(
      GridPos.fromJson(json),
      json['id']?.toString() ?? '',
    );
  }
}

/// A teleport pad. Any two pads sharing the same [pairId] teleport the
/// player between each other.
class TeleportObject {
  final GridPos pos;
  final String pairId;

  const TeleportObject(this.pos, this.pairId);

  factory TeleportObject.fromJson(Map<String, dynamic> json) {
    return TeleportObject(
      GridPos.fromJson(json),
      json['id']?.toString() ?? '',
    );
  }
}

/// A trap tile. When [activeMs]/[inactiveMs] are set (> 0) the trap blinks
/// on and off on a fixed cycle instead of being permanently dangerous,
/// covering the "timed obstacles" mechanic from later levels.
class TrapObject {
  final GridPos pos;
  final int activeMs;
  final int inactiveMs;

  const TrapObject(this.pos, {this.activeMs = 0, this.inactiveMs = 0});

  bool get isTimed => activeMs > 0 && inactiveMs > 0;

  /// Whether the trap is dangerous at [elapsedMs] since level start.
  bool isDangerousAt(int elapsedMs) {
    if (!isTimed) return true;
    final cycle = activeMs + inactiveMs;
    final phase = elapsedMs % cycle;
    return phase < activeMs;
  }

  factory TrapObject.fromJson(Map<String, dynamic> json) {
    return TrapObject(
      GridPos.fromJson(json),
      activeMs: (json['activeMs'] as num?)?.toInt() ?? 0,
      inactiveMs: (json['inactiveMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// An obstacle that patrols back and forth along [path] and is dangerous on
/// contact. [stepMs] is how long it takes to move one grid cell.
class MovingObstacle {
  final List<GridPos> path;
  final int stepMs;

  const MovingObstacle(this.path, {this.stepMs = 400});

  GridPos positionAt(int elapsedMs) {
    if (path.length < 2) return path.first;
    final totalSteps = (path.length - 1) * 2;
    final stepIndex = (elapsedMs ~/ stepMs) % totalSteps;
    final forward = stepIndex < path.length - 1;
    final index = forward ? stepIndex : totalSteps - stepIndex;
    return path[index];
  }

  factory MovingObstacle.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'] as List<dynamic>? ?? const [];
    final path = rawPath
        .map((p) => GridPos.fromJson(p as Map<String, dynamic>))
        .toList(growable: false);
    if (path.isEmpty) {
      throw const FormatException('MovingObstacle requires a non-empty path');
    }
    return MovingObstacle(
      path,
      stepMs: (json['stepMs'] as num?)?.toInt() ?? 400,
    );
  }
}

/// A wall segment that slides open/closed on a fixed timer, used by the
/// "moving walls" mechanic in later levels. Acts as a normal wall while
/// [isOpenAt] is false.
class MovingWall {
  final GridPos pos;
  final int openMs;
  final int closedMs;

  const MovingWall(this.pos, {required this.openMs, required this.closedMs});

  bool isOpenAt(int elapsedMs) {
    final cycle = openMs + closedMs;
    if (cycle <= 0) return false;
    final phase = elapsedMs % cycle;
    return phase < openMs;
  }

  factory MovingWall.fromJson(Map<String, dynamic> json) {
    return MovingWall(
      GridPos.fromJson(json),
      openMs: (json['openMs'] as num?)?.toInt() ?? 1000,
      closedMs: (json['closedMs'] as num?)?.toInt() ?? 1000,
    );
  }
}
