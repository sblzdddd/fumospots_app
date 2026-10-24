import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n/i18n.dart';
import '../../core/services/image_cache_service.dart';
import '../home/bottom_navigation.dart';
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
  final LocaleController _locale = GetIt.instance<LocaleController>();
  final ImageCacheService _images = GetIt.instance<ImageCacheService>();
  final M3EDropdownController<AppLanguage> _languageDropdown =
      M3EDropdownController<AppLanguage>();
  bool _clearing = false;
  bool _syncingLanguage = false;

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
    _locale.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _theme.removeListener(_onChanged);
    _visual.removeListener(_onChanged);
    _locale.removeListener(_onLocaleChanged);
    _languageDropdown.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onLocaleChanged() {
    _syncLanguageDropdown();
    _onChanged();
  }

  void _syncLanguageDropdown() {
    if (_syncingLanguage ||
        !_languageDropdown.initialized ||
        _languageDropdown.items.isEmpty) {
      return;
    }
    final wanted = _locale.language;
    final current = _languageDropdown.selectedValues;
    if (current.length == 1 && current.first == wanted) {
      return;
    }
    _syncingLanguage = true;
    _languageDropdown.clearAll();
    _languageDropdown.selectWhere((item) => item.value == wanted);
    _syncingLanguage = false;
  }

  List<M3EDropdownItem<AppLanguage>> _languageItems(BuildContext context) {
    return [
      for (final language in AppLanguage.values)
        M3EDropdownItem<AppLanguage>(
          value: language,
          label: context.t(language.labelKey),
          selected: language == _locale.language,
        ),
    ];
  }

  void _onLanguageChanged(List<M3EDropdownItem<AppLanguage>> items) {
    if (_syncingLanguage || items.isEmpty) {
      return;
    }
    _locale.setLanguage(items.first.value);
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
        SnackBar(content: Text(context.t(S.imageCacheCleared))),
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
      appBar: AppBar(title: Text(context.t(S.settings))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SectionLabel(context.t(S.settingsLanguage)),
          const SizedBox(height: 8),
          M3EDropdownMenu<AppLanguage>(
            items: _languageItems(context),
            controller: _languageDropdown,
            singleSelect: true,
            searchEnabled: false,
            showChipAnimation: false,
            maxSelections: 1,
            containerRadius: 28,
            haptic: M3EHapticFeedback.light,
            fieldStyle: M3EDropdownFieldStyle(
              hintText: context.t(S.settingsLanguage),
              showClearIcon: false,
              padding: const EdgeInsets.all(14),
            ),
            dropdownStyle: M3EDropdownStyle(
              elevation: 4,
              maxHeight: 280,
              marginTop: 4,
              expandDirection: ExpandDirection.auto,
              contentPadding: const EdgeInsets.all(8),
              backgroundColor: cs.surfaceContainer,
            ),
            itemStyle: M3EDropdownItemStyle(
              backgroundColor: cs.surfaceContainerHigh,
              selectedBackgroundColor: cs.secondaryContainer,
              selectedTextColor: cs.onSecondaryContainer,
              textColor: cs.onSurface,
              outerRadius: 18,
              innerRadius: 6,
              itemGap: 3,
              itemPadding: const EdgeInsets.all(12),
              selectedIcon: Icon(
                Icons.check_rounded,
                color: cs.onSecondaryContainer,
              ),
            ),
            onSelectionChanged: _onLanguageChanged,
          ),
          _SectionLabel(context.t(S.settingsAppearance)),
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
            actions: [
              M3EToggleButtonGroupAction(
                label: Text(context.t(S.themeLight)),
                icon: const FaIcon(FontAwesomeIcons.sun, size: 14),
              ),
              M3EToggleButtonGroupAction(
                label: Text(context.t(S.themeDark)),
                icon: const FaIcon(FontAwesomeIcons.moon, size: 14),
              ),
              M3EToggleButtonGroupAction(
                label: Text(context.t(S.themeSystem)),
                icon: const FaIcon(FontAwesomeIcons.mobile, size: 14),
              ),
            ],
          ),
          if (mapPageEnabled) ...[
            const SizedBox(height: 8),
            _SectionLabel(context.t(S.settingsStartPage)),
            const SizedBox(height: 8),
            M3EToggleButtonGroup(
              type: M3EButtonGroupType.connected,
              style: M3EButtonStyle.tonal,
              shape: M3EButtonShape.round,
              selectedIndex: _visual.startPage == HomeStartPage.map ? 1 : 0,
              onSelectedIndexChanged: (index) {
                if (index != null) {
                  _visual.setStartPage(
                    index == 0 ? HomeStartPage.posts : HomeStartPage.map,
                  );
                }
              },
              actions: [
                M3EToggleButtonGroupAction(
                  label: Text(context.t(S.navPosts)),
                  icon: const FaIcon(FontAwesomeIcons.tableCellsLarge, size: 14),
                ),
                M3EToggleButtonGroupAction(
                  label: Text(context.t(S.navMap)),
                  icon: const FaIcon(FontAwesomeIcons.map, size: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _SectionLabel(context.t(S.settingsVisual)),
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
                          context.t(S.blurEffects),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.t(
                            _visual.blurEnabled ? S.blurOn : S.blurOff,
                          ),
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
          _SectionLabel(context.t(S.settingsStorage)),
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
                          context.t(S.clearImageCache),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.t(S.clearImageCacheHint),
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
