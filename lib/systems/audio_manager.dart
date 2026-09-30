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

/// Central audio playback point.
///
/// SFX rotate through a small pool of low-latency players so a coin ding
/// isn't cut off by the very next move blip. Every call is wrapped
/// defensively: a missing asset is logged in debug and otherwise ignored,
/// so audio can never crash gameplay. Assets are synthesized by
/// `tool/generate_audio.py`.
class AudioManager {
  AudioManager(this._storage);

  final StorageService _storage;
  final List<AudioPlayer> _sfxPool = List.generate(
    _poolSize,
    (i) => AudioPlayer(playerId: 'sfx_$i')..setPlayerMode(PlayerMode.lowLatency),
  );
  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  int _nextPlayer = 0;
  bool _musicStarted = false;

  static const int _poolSize = 4;
  static const double _sfxVolume = 0.7;
  static const double _musicVolume = 0.35;

  static const Map<SoundEffect, String> _assetPaths = {
    SoundEffect.move: 'audio/move.wav',
    SoundEffect.collectCoin: 'audio/collect_coin.wav',
    SoundEffect.collectKey: 'audio/collect_key.wav',
    SoundEffect.unlockDoor: 'audio/unlock_door.wav',
    SoundEffect.trap: 'audio/trap.wav',
    SoundEffect.death: 'audio/death.wav',
    SoundEffect.levelComplete: 'audio/level_complete.wav',
    SoundEffect.buttonClick: 'audio/button_click.wav',
    SoundEffect.teleport: 'audio/teleport.wav',
  };

  static const String _musicAsset = 'audio/background_music.wav';

  Future<void> playSfx(SoundEffect effect) async {
    if (!_storage.soundEnabled) return;
    final path = _assetPaths[effect];
    if (path == null) return;
    final player = _sfxPool[_nextPlayer];
    _nextPlayer = (_nextPlayer + 1) % _poolSize;
    try {
      await player.stop();
      await player.play(AssetSource(path), volume: _sfxVolume);
    } catch (e) {
      _logMissingAsset(path, e);
    }
  }

  Future<void> startMusic() async {
    if (!_storage.musicEnabled || _musicStarted) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource(_musicAsset), volume: _musicVolume);
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
      debugPrint('AudioManager: skipping "$path": $error');
    }
  }

  void dispose() {
    for (final p in _sfxPool) {
      p.dispose();
    }
    _musicPlayer.dispose();
  }
}
