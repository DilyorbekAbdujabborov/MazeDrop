import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../systems/audio_manager.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.storage, required this.audio});

  final StorageService storage;
  final AudioManager audio;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sound = widget.storage.soundEnabled;
  late bool _music = widget.storage.musicEnabled;
  late bool _vibration = widget.storage.vibrationEnabled;

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears every unlocked level, star, and best score. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.storage.resetProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: AppTheme.screenBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Sound'),
              value: _sound,
              onChanged: (value) {
                setState(() => _sound = value);
                widget.storage.setSoundEnabled(value);
              },
            ),
            SwitchListTile(
              title: const Text('Music'),
              value: _music,
              onChanged: (value) {
                setState(() => _music = value);
                widget.storage.setMusicEnabled(value);
                widget.audio.setMusicEnabled(value);
              },
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              value: _vibration,
              onChanged: (value) {
                setState(() => _vibration = value);
                widget.storage.setVibrationEnabled(value);
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: AppColors.danger),
              title: const Text('Reset Progress'),
              onTap: _resetProgress,
            ),
          ],
        ),
      ),
    );
  }
}
