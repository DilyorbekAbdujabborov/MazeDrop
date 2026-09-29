import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazedrop/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fresh install has sane defaults', () async {
    final storage = await StorageService.create();
    expect(storage.isLevelUnlocked(1), isTrue);
    expect(storage.isLevelUnlocked(2), isFalse);
    expect(storage.starsFor(1), 0);
    expect(storage.soundEnabled, isTrue);
    expect(storage.musicEnabled, isTrue);
    expect(storage.vibrationEnabled, isTrue);
    expect(storage.controlScheme, 'swipe');
  });

  test('recording a result unlocks the next level and keeps best scores', () async {
    final storage = await StorageService.create();

    await storage.recordLevelResult(levelId: 1, stars: 2, timeSeconds: 20, moves: 15);
    expect(storage.isLevelUnlocked(2), isTrue);
    expect(storage.starsFor(1), 2);
    expect(storage.bestTimeFor(1), 20);
    expect(storage.bestMovesFor(1), 15);

    // A worse run should not overwrite the best score.
    await storage.recordLevelResult(levelId: 1, stars: 1, timeSeconds: 40, moves: 30);
    expect(storage.starsFor(1), 2);
    expect(storage.bestTimeFor(1), 20);
    expect(storage.bestMovesFor(1), 15);

    // A better run should raise it.
    await storage.recordLevelResult(levelId: 1, stars: 3, timeSeconds: 10, moves: 8);
    expect(storage.starsFor(1), 3);
    expect(storage.bestTimeFor(1), 10);
    expect(storage.bestMovesFor(1), 8);
  });

  test('resetProgress clears stars and unlocks but keeps settings', () async {
    final storage = await StorageService.create();
    await storage.recordLevelResult(levelId: 1, stars: 3, timeSeconds: 10, moves: 8);
    await storage.setSoundEnabled(false);

    await storage.resetProgress();

    expect(storage.starsFor(1), 0);
    expect(storage.isLevelUnlocked(2), isFalse);
    expect(storage.soundEnabled, isFalse);
  });
}
