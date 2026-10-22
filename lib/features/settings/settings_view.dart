import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

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

  static const _themeModes = [
    ThemeMode.light,
    ThemeMode.dark,
    ThemeMode.system,
  ];

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionLabel('Appearance'),
          const SizedBox(height: 8),
          M3EToggleButtonGroup(
            type: M3EButtonGroupType.connected,
            style: M3EButtonStyle.tonal,
            shape: M3EButtonShape.round,
            selectedIndex: _themeModes.indexOf(_theme.mode),
            onSelectedIndexChanged: (index) {
              if (index != null) {
                _theme.setMode(_themeModes[index]);
              }
            },
            actions: const [
              M3EToggleButtonGroupAction(
                label: Text('Light'),
                icon: FaIcon(FontAwesomeIcons.sun, size: 14),
              ),
              M3EToggleButtonGroupAction(
                label: Text('Dark'),
                icon: FaIcon(FontAwesomeIcons.moon, size: 14),
              ),
              M3EToggleButtonGroupAction(
                label: Text('System'),
                icon: FaIcon(FontAwesomeIcons.mobile, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _SectionLabel('Visual'),
          M3ESegmentedColumn(
            selectionMode: M3ESelectionMode.multiple,
            selectionTrigger: M3ESelectionTrigger.none,
            splashFactory: InkSparkle.splashFactory,
            selectedColor: cs.primaryContainer.withValues(alpha: 0.4),
            isSelected: (index) => index == 0 && _visual.blurEnabled,
            onTap: (_) => _visual.setBlurEnabled(!_visual.blurEnabled),
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  FaIcon(
                    FontAwesomeIcons.droplet,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blur effects',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _visual.blurEnabled
                              ? 'Blur behind the navigation bar'
                              : 'Solid navigation bar',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IgnorePointer(
                    child: Switch(
                      value: _visual.blurEnabled,
                      onChanged: _visual.setBlurEnabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _SectionLabel('Storage'),
          M3ESegmentedColumn(
            splashFactory: InkSparkle.splashFactory,
            onTap: _clearing ? null : (_) => _clearImageCache(),
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  FaIcon(
                    FontAwesomeIcons.broom,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clear image cache',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Free space and reset cached thumbnails',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_clearing)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: M3ELoadingIndicator(
                        constraints: BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
