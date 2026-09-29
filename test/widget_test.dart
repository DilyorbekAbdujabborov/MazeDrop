import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mazedrop/screens/main_menu.dart';
import 'package:mazedrop/services/storage_service.dart';
import 'package:mazedrop/systems/ad_service.dart';
import 'package:mazedrop/systems/analytics_service.dart';
import 'package:mazedrop/systems/audio_manager.dart';
import 'package:mazedrop/systems/level_manager.dart';
import 'package:mazedrop/theme/app_theme.dart';

void main() {
  testWidgets('Main menu shows the logo and a PLAY button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MainMenuScreen(
          storage: storage,
          levelManager: LevelManager(storage),
          audio: AudioManager(storage),
          analytics: AnalyticsService(),
          ads: AdService(),
        ),
      ),
    );

    expect(find.text('MazeDrop'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
