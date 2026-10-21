import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/image_cache_service.dart';
import 'theme_controller.dart';
import 'visual_settings_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final ThemeController _theme = GetIt.instance<ThemeController>();
  final VisualSettingsController _visual =
      GetIt.instance<VisualSettingsController>();
  final ImageCacheService _images = GetIt.instance<ImageCacheService>();
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onChanged);
    _visual.addListener(_onChanged);
  }

  @override
  void dispose() {
    _theme.removeListener(_onChanged);
    _visual.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _clearImageCache() async {
    if (_clearing) {
      return;
    }
    setState(() => _clearing = true);
    try {
      await _images.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image cache cleared.')),
      );
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionLabel('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: FaIcon(FontAwesomeIcons.sun, size: 14),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: FaIcon(FontAwesomeIcons.moon, size: 14),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: FaIcon(FontAwesomeIcons.mobile, size: 14),
                ),
              ],
              selected: {_theme.mode},
              onSelectionChanged: (next) {
                if (next.isNotEmpty) {
                  _theme.setMode(next.first);
                }
              },
            ),
          ),
          const Divider(height: 1),
          const _SectionLabel('Visual'),
          SwitchListTile(
            secondary: const FaIcon(FontAwesomeIcons.droplet, size: 18),
            title: const Text('Blur effects'),
            subtitle: Text(
              _visual.blurEnabled
                  ? 'Progressive blur on the app bar'
                  : 'Gradient fade only (no blur)',
            ),
            value: _visual.blurEnabled,
            onChanged: _visual.setBlurEnabled,
          ),
          const Divider(height: 1),
          const _SectionLabel('Storage'),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.broom, size: 18),
            title: const Text('Clear image cache'),
            subtitle: const Text('Free space and reset cached thumbnails'),
            trailing: _clearing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _clearing ? null : _clearImageCache,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
