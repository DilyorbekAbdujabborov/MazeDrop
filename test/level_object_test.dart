import 'package:flutter_test/flutter_test.dart';
import 'package:mazedrop/models/level_object.dart';
import 'package:mazedrop/models/player_state.dart';

void main() {
  group('GridPos', () {
    test('equal coordinates compare equal', () {
      expect(const GridPos(2, 3), const GridPos(2, 3));
      expect(const GridPos(2, 3), isNot(const GridPos(3, 2)));
    });
  });

  group('TrapObject', () {
    test('a plain trap is always dangerous', () {
      const trap = TrapObject(GridPos(0, 0));
      expect(trap.isDangerousAt(0), isTrue);
      expect(trap.isDangerousAt(99999), isTrue);
    });

    test('a timed trap blinks between active and inactive', () {
      const trap = TrapObject(GridPos(0, 0), activeMs: 1000, inactiveMs: 1000);
      expect(trap.isDangerousAt(0), isTrue);
      expect(trap.isDangerousAt(999), isTrue);
      expect(trap.isDangerousAt(1000), isFalse);
      expect(trap.isDangerousAt(1999), isFalse);
      expect(trap.isDangerousAt(2000), isTrue);
    });
  });

  group('MovingObstacle', () {
    test('patrols back and forth along its path', () {
      final obstacle = MovingObstacle(
        const [GridPos(0, 0), GridPos(1, 0), GridPos(2, 0)],
        stepMs: 100,
      );
      expect(obstacle.positionAt(0), const GridPos(0, 0));
      expect(obstacle.positionAt(100), const GridPos(1, 0));
      expect(obstacle.positionAt(200), const GridPos(2, 0));
      expect(obstacle.positionAt(300), const GridPos(1, 0));
      expect(obstacle.positionAt(400), const GridPos(0, 0));
      expect(obstacle.positionAt(400 + 400), const GridPos(0, 0));
    });
  });

  group('PlayerState', () {
    test('remainingSeconds rounds up so the HUD never shows 0 early', () {
      final s = PlayerState(position: const GridPos(0, 0), remainingMs: 1);
      expect(s.remainingSeconds, 1);
      s.remainingMs = 0;
      expect(s.remainingSeconds, 0);
      s.remainingMs = 10500;
      expect(s.remainingSeconds, 11);
    });
  });

  group('MovingWall', () {
    test('cycles open/closed on a fixed timer', () {
      const wall = MovingWall(GridPos(0, 0), openMs: 500, closedMs: 500);
      expect(wall.isOpenAt(0), isTrue);
      expect(wall.isOpenAt(499), isTrue);
      expect(wall.isOpenAt(500), isFalse);
      expect(wall.isOpenAt(999), isFalse);
      expect(wall.isOpenAt(1000), isTrue);
    });
  });
}
