import 'package:flutter_test/flutter_test.dart';
import 'package:mazedrop/models/level.dart';
import 'package:mazedrop/models/level_object.dart';

Map<String, dynamic> _validJson() => {
      'id': 1,
      'width': 3,
      'height': 3,
      'player': {'x': 0, 'y': 0},
      'exit': {'x': 2, 'y': 2},
      'walls': [
        {'x': 1, 'y': 1},
      ],
      'traps': [],
      'keys': [],
      'doors': [],
      'teleports': [],
      'coins': [],
    };

void main() {
  test('parses a well-formed level', () {
    final level = Level.fromJson(_validJson());
    expect(level.id, 1);
    expect(level.width, 3);
    expect(level.height, 3);
    expect(level.player, const GridPos(0, 0));
    expect(level.exit, const GridPos(2, 2));
    expect(level.walls, contains(const GridPos(1, 1)));
    expect(level.inBounds(const GridPos(2, 2)), isTrue);
    expect(level.inBounds(const GridPos(3, 0)), isFalse);
  });

  test('missing required field throws FormatException', () {
    final json = _validJson()..remove('exit');
    expect(() => Level.fromJson(json), throwsFormatException);
  });

  test('non-positive dimensions throw FormatException', () {
    final json = _validJson();
    json['width'] = 0;
    expect(() => Level.fromJson(json), throwsFormatException);
  });

  test('malformed nested object throws FormatException', () {
    final json = _validJson();
    json['walls'] = [
      {'x': 'not-a-number', 'y': 1},
    ];
    expect(() => Level.fromJson(json), throwsFormatException);
  });
}
