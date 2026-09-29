# MazeDrop

A 2D grid-maze puzzle game: guide a water droplet through a maze to the
exit, avoiding traps and hazards, with 30 hand-tuned levels of growing
difficulty. Built with Flutter + Flame.

## Status

This is the full vertical slice plus all 30 levels and the complete
supporting architecture (progress storage, audio/ads/analytics
scaffolding). It has **not** been run on a physical device or emulator in
this environment — see **Known limitation** below.

Verified in this environment:

```bash
flutter pub get     # OK
flutter analyze     # No issues found
flutter test        # All tests passed
```

`flutter build apk` could **not** be verified here — see below.

## Architecture

```
lib/
  main.dart                 App entry point, wires services together
  game/
    maze_drop_game.dart      Flame FlameGame: grid layout, input, gameplay rules
    render_utils.dart        Shared tile-drawing helper
    components/              wall, exit, trap, key, door, coin, teleport, player
  systems/
    level_loader.dart        Loads + validates level JSON, graceful errors
    level_manager.dart       Unlock/star/best-score facade over StorageService
    audio_manager.dart       SFX/music playback (safe no-op if asset missing)
    ad_service.dart          Rewarded "continue" + rate-limited interstitial
    analytics_service.dart   Event logging (local now, Firebase-ready)
  screens/                  main_menu, level_select, game_screen, settings
  widgets/                  game_button, life_indicator, level_card
  models/                   level.dart, level_object.dart, player_state.dart
  services/storage_service.dart   SharedPreferences-backed progress/settings
  theme/app_theme.dart       Colors, text styles, animation durations
assets/levels/level_01.json .. level_30.json
tool/generate_levels.py     Deterministic level generator (see below)
```

### Adding/editing levels

Levels are plain JSON (`assets/levels/level_XX.json`), never hardcoded in
Dart. To add a new one by hand, copy the JSON shape of an existing level.

To regenerate the whole set deterministically instead (guaranteed
solvable, same output every run for a given spec), edit `LEVEL_SPECS` in
`tool/generate_levels.py` and run:

```bash
python3 tool/generate_levels.py assets/levels
```

The script BFS-verifies every generated level is solvable (accounting for
locked doors and teleports) before writing it, and refuses to write an
unsolvable level.

### Placeholder architecture (by design)

Per the project brief, these are wired up as real, working code paths but
intentionally run on placeholders until real assets/accounts exist:

- **Audio**: `AudioManager` expects files under `assets/audio/*.mp3`
  (see the file names in `audio_manager.dart`). None are bundled yet, so
  playback calls fail silently and gameplay continues normally.
- **Ads**: `AdService` uses Google's public **test** AdMob ad unit ids.
  Swap them for real ids in `ad_service.dart` (and the app id in
  `android/app/src/main/AndroidManifest.xml`) before a real release.
- **Analytics**: `AnalyticsService` logs events to the debug console only.
  No `firebase_analytics` dependency or `google-services.json` is wired
  up (there's no Firebase project to point it at). Swap `_send()`'s body
  for `FirebaseAnalytics.instance.logEvent` once one exists.

## Known limitation: Android build not verified here

This container has no Android SDK, and the SDK's official host
(`dl.google.com`, which serves `cmdline-tools`, platform/build-tools, and
the Google Maven repo the Android Gradle Plugin needs) is blocked by this
environment's outbound network policy (confirmed: `403 Forbidden` from
the egress proxy). That is an organization network policy decision, not a
bug in this project — the same block would stop `flutter build apk` from
downloading its Gradle dependencies even after installing an SDK.

**On a normal machine or CI runner with full network access**, this
project is expected to build normally:

```bash
flutter pub get
flutter build apk --release   # or: flutter build appbundle --release
```

Before a real Play Store release, also:
1. Replace the AdMob test ids (see above).
2. Add a real release-signing config in `android/app/build.gradle.kts`
   (this project currently only has debug signing set up).
3. Drop real audio files into `assets/audio/` and declare them in
   `pubspec.yaml`.
