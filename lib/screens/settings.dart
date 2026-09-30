import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../systems/audio_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/screen_header.dart';

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
  late String _controls = widget.storage.controlScheme;

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 40),
              const SizedBox(height: 12),
              Text('Reset progress?', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Every unlocked level, star and best score will be erased. This cannot be undone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              GameButton(
                label: 'Reset everything',
                danger: true,
                expand: true,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 10),
              GameButton(
                label: 'Cancel',
                filled: false,
                expand: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
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
      body: Container(
        decoration: AppTheme.screenBackground,
        child: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: 'Settings'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    _Section(
                      label: 'AUDIO & FEEDBACK',
                      children: [
                        _ToggleTile(
                          icon: Icons.volume_up_rounded,
                          title: 'Sound effects',
                          value: _sound,
                          onChanged: (v) {
                            setState(() => _sound = v);
                            widget.storage.setSoundEnabled(v);
                          },
                        ),
                        _ToggleTile(
                          icon: Icons.music_note_rounded,
                          title: 'Music',
                          value: _music,
                          onChanged: (v) {
                            setState(() => _music = v);
                            widget.storage.setMusicEnabled(v);
                            widget.audio.setMusicEnabled(v);
                          },
                        ),
                        _ToggleTile(
                          icon: Icons.vibration_rounded,
                          title: 'Vibration',
                          value: _vibration,
                          onChanged: (v) {
                            setState(() => _vibration = v);
                            widget.storage.setVibrationEnabled(v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      label: 'CONTROLS',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: _Segmented(
                            value: _controls,
                            options: const {
                              'swipe': ('Swipe', Icons.swipe_rounded),
                              'dpad': ('D-pad', Icons.gamepad_rounded),
                            },
                            onChanged: (v) {
                              setState(() => _controls = v);
                              widget.storage.setControlScheme(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      label: 'DATA',
                      children: [
                        _ActionTile(
                          icon: Icons.restart_alt_rounded,
                          title: 'Reset progress',
                          subtitle: 'Clears levels, stars and best scores',
                          color: AppColors.danger,
                          onTap: _resetProgress,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        Container(
          decoration: AppTheme.glassCard(radius: 22),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.color = AppColors.primary});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withAlpha(40),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            _IconBadge(icon: icon),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.options, required this.onChanged});

  final String value;
  final Map<String, (String, IconData)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.entries.map((e) {
        final selected = e.key == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: AppTheme.shortAnim,
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: selected ? AppTheme.primaryGradient : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(e.value.$2, size: 18, color: selected ? AppColors.background : AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    e.value.$1,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.background : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
