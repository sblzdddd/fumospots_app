import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../post/post_format.dart';
import '../character_catalog_controller.dart';
import '../character_format.dart';
import 'character_filter_controller.dart';

class CharacterFilterBar extends StatefulWidget {
  const CharacterFilterBar({
    super.key,
    this.floating = false,
    this.hintText = 'Filter by character',
  });

  /// Elevated floating style for the map overlay.
  final bool floating;

  final String hintText;

  @override
  State<CharacterFilterBar> createState() => _CharacterFilterBarState();
}

class _CharacterFilterBarState extends State<CharacterFilterBar> {
  final CharacterCatalogController _catalog =
      GetIt.instance<CharacterCatalogController>();
  final CharacterFilterController _filter =
      GetIt.instance<CharacterFilterController>();
  final M3EDropdownController<int> _dropdown = M3EDropdownController<int>();

  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _filter.addListener(_syncFromFilter);
  }

  @override
  void dispose() {
    _filter.removeListener(_syncFromFilter);
    _dropdown.dispose();
    super.dispose();
  }

  Future<List<M3EDropdownItem<int>>> _loadItems() async {
    await _catalog.load();
    if (_catalog.error != null && _catalog.characters.isEmpty) {
      throw StateError(_catalog.error!);
    }

    final locale = deviceLocale();
    final selected = _filter.selectedIds.toSet();
    return [
      for (final character in _catalog.characters)
        M3EDropdownItem<int>(
          value: character.id,
          label: characterCatalogName(character, locale),
          selected: selected.contains(character.id),
        ),
    ];
  }

  void _onSelectionChanged(List<M3EDropdownItem<int>> items) {
    if (_syncing) {
      return;
    }
    _syncing = true;
    _filter.setSelectedIds([for (final item in items) item.value]);
    _syncing = false;
  }

  void _syncFromFilter() {
    if (_syncing || !_dropdown.initialized || _dropdown.items.isEmpty) {
      return;
    }

    final wanted = _filter.selectedIds.toSet();
    final current = _dropdown.selectedValues.toSet();
    if (wanted.length == current.length && wanted.containsAll(current)) {
      return;
    }

    _syncing = true;
    _dropdown.clearAll();
    if (wanted.isNotEmpty) {
      _dropdown.selectWhere((item) => wanted.contains(item.value));
    }
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final menu = M3EDropdownMenu<int>.future(
      future: _loadItems,
      controller: _dropdown,
      singleSelect: false,
      searchEnabled: true,
      showChipAnimation: true,
      maxSelections: 0,
      enabled: true,
      containerRadius: 28,
      haptic: M3EHapticFeedback.light,
      openMotion: M3EMotion.custom(stiffness: 500, damping: 0.6),
      closeMotion: M3EMotion.custom(stiffness: 500, damping: 0.6),
      fieldStyle: M3EDropdownFieldStyle(
        hintText: widget.hintText,
        showClearIcon: true,
        padding: const EdgeInsets.all(14),
        pressedScale: 0.98,
        backgroundColor: widget.floating ? colors.surface : null,
      ),
      dropdownStyle: M3EDropdownStyle(
        elevation: 4,
        maxHeight: 350,
        marginTop: 4,
        expandDirection: ExpandDirection.auto,
        contentPadding: const EdgeInsets.all(8),
        backgroundColor: colors.surfaceContainer,
      ),
      searchStyle: const M3ESearchStyle(
        hintText: 'Search characters…',
        filled: false,
        autofocus: false,
        showClearIcon: true,
        searchDebounceMs: 0,
        contentPadding: EdgeInsets.all(8),
      ),
      chipStyle: M3EChipStyle(
        backgroundColor: colors.secondaryContainer,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.onSecondaryContainer,
        ),
        deleteIcon: Icon(
          Icons.close_rounded,
          size: 16,
          color: colors.onSecondaryContainer,
        ),
        borderRadius: BorderRadius.circular(20),
        spacing: 6,
        runSpacing: 6,
        wrap: true,
        maxDisplayCount: 4,
        padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
        openMotion: M3EMotion.custom(stiffness: 500, damping: 0.6),
        closeMotion: M3EMotion.custom(stiffness: 500, damping: 0.6),
        pressedScale: 0.98,
      ),
      itemStyle: M3EDropdownItemStyle(
        backgroundColor: colors.surfaceContainerHigh,
        selectedBackgroundColor: colors.secondaryContainer,
        selectedTextColor: colors.onSecondaryContainer,
        textColor: colors.onSurface,
        outerRadius: 18,
        innerRadius: 6,
        itemGap: 3,
        itemPadding: const EdgeInsets.all(12),
        pressedScale: 0.98,
        selectedIcon: Icon(
          Icons.check_rounded,
          color: colors.onSecondaryContainer,
        ),
      ),
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _catalog.error != null
              ? "Couldn't load characters."
              : 'No matching characters.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
      closeOnBackButton: false,
      onSelectionChanged: _onSelectionChanged,
    );
    final wrapped = NotificationListener<ScrollNotification>(
      onNotification: (_) => true,
      child: menu,
    );

    if (!widget.floating) {
      return wrapped;
    }

    return Material(
      color: colors.surface.withValues(alpha: 0.92),
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(28),
      child: wrapped,
    );
  }
}
