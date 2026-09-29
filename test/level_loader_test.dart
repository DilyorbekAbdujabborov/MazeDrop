import 'package:flutter_test/flutter_test.dart';
import 'package:mazedrop/systems/level_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every bundled level asset without error', () async {
    const loader = LevelLoader();
    for (var id = 1; id <= 30; id++) {
      final level = await loader.load(id);
      expect(level.id, id);
      expect(level.inBounds(level.player), isTrue);
      expect(level.inBounds(level.exit), isTrue);
    }
  });

  test('missing level asset throws a graceful LevelLoadException', () async {
    const loader = LevelLoader();
    expect(loader.load(999), throwsA(isA<LevelLoadException>()));
  });
}
