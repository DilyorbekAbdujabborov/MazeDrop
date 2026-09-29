import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/level.dart';

/// Thrown when a level's JSON is missing or malformed. Callers should show
/// a graceful error UI, never let this crash the app.
class LevelLoadException implements Exception {
  final String message;
  const LevelLoadException(this.message);

  @override
  String toString() => 'LevelLoadException: $message';
}

/// Loads level definitions from `assets/levels/level_XX.json`.
class LevelLoader {
  const LevelLoader();

  static String assetPathFor(int id) =>
      'assets/levels/level_${id.toString().padLeft(2, '0')}.json';

  Future<Level> load(int id) async {
    final path = assetPathFor(id);
    String raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (e) {
      throw LevelLoadException('Missing asset for level $id ($path): $e');
    }

    Map<String, dynamic> jsonMap;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Level JSON root must be an object');
      }
      jsonMap = decoded;
    } catch (e) {
      throw LevelLoadException('Level $id has invalid JSON: $e');
    }

    try {
      return Level.fromJson(jsonMap);
    } catch (e) {
      throw LevelLoadException('Level $id failed to parse: $e');
    }
  }
}
