import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

enum SoundEffect {
  move,
  collectCoin,
  collectKey,
  unlockDoor,
  trap,
  death,
  levelComplete,
  buttonClick,
  teleport,
}

/// Central audio playback point. Every call is wrapped defensively: if the
/// backing asset file is missing (this MVP ships with no bundled audio
/// yet), the failure is swallowed and gameplay continues silently instead
/// of crashing. Drop real files into `assets/audio/` using the names below
/// and declare them in pubspec.yaml to bring sound online.
class AudioManager {
  AudioManager(this._storage);

  final StorageService _storage;
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  bool _musicStarted = false;

  static const Map<SoundEffect, String> _assetPaths = {
    SoundEffect.move: 'audio/move.mp3',
    SoundEffect.collectCoin: 'audio/collect_coin.mp3',
    SoundEffect.collectKey: 'audio/collect_key.mp3',
    SoundEffect.unlockDoor: 'audio/unlock_door.mp3',
    SoundEffect.trap: 'audio/trap.mp3',
    SoundEffect.death: 'audio/death.mp3',
    SoundEffect.levelComplete: 'audio/level_complete.mp3',
    SoundEffect.buttonClick: 'audio/button_click.mp3',
    SoundEffect.teleport: 'audio/teleport.mp3',
  };

  static const String _musicAsset = 'audio/background_music.mp3';

  Future<void> playSfx(SoundEffect effect) async {
    if (!_storage.soundEnabled) return;
    final path = _assetPaths[effect];
    if (path == null) return;
    try {
      await _sfxPlayer.play(AssetSource(path));
    } catch (e) {
      _logMissingAsset(path, e);
    }
  }

  Future<void> startMusic() async {
    if (!_storage.musicEnabled || _musicStarted) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource(_musicAsset));
      _musicStarted = true;
    } catch (e) {
      _logMissingAsset(_musicAsset, e);
    }
  }

  Future<void> stopMusic() async {
    _musicStarted = false;
    try {
      await _musicPlayer.stop();
    } catch (_) {
      // Nothing to stop.
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    if (enabled) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  void _logMissingAsset(String path, Object error) {
    if (kDebugMode) {
      debugPrint('AudioManager: skipping "$path" (asset missing?): $error');
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
