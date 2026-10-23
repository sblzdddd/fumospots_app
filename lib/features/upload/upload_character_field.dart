import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../character/character_catalog_controller.dart';
import '../character/character_format.dart';
import '../post/post_format.dart';
import 'upload_section.dart';

class UploadCharacterField extends StatefulWidget {
  const UploadCharacterField({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.initialSelectedIds = const [],
  });

  final bool enabled;
  final ValueChanged<List<int>> onChanged;
  final List<int> initialSelectedIds;

  @override
  State<UploadCharacterField> createState() => _UploadCharacterFieldState();
}

class _UploadCharacterFieldState extends State<UploadCharacterField> {
  final CharacterCatalogController _catalog =
      GetIt.instance<CharacterCatalogController>();
  final M3EDropdownController<int> _dropdown = M3EDropdownController<int>();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _catalog.addListener(_onCatalog);
    unawaited(_catalog.load());
  }

  @override
  void didUpdateWidget(covariant UploadCharacterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.initialSelectedIds, widget.initialSelectedIds)) {
      _syncSelection();
    }
  }

  @override
  void dispose() {
    _catalog.removeListener(_onCatalog);
    _dropdown.dispose();
    super.dispose();
  }

  void _onCatalog() {
    if (mounted) setState(() {});
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<List<M3EDropdownItem<int>>> _loadItems() async {
    await _catalog.load();
    if (_catalog.error != null && _catalog.characters.isEmpty) {
      throw StateError(_catalog.error!);
    }
    final locale = deviceLocale();
    final selected = widget.initialSelectedIds.toSet();
    final items = [
      for (final character in _catalog.characters)
        M3EDropdownItem<int>(
          value: character.id,
          label: characterCatalogName(character, locale),
          selected: selected.contains(character.id),
        ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSelection());
    return items;
  }

  void _syncSelection() {
    if (_syncing || !_dropdown.initialized || _dropdown.items.isEmpty) {
      return;
    }
    final wanted = widget.initialSelectedIds.toSet();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UploadSectionLabel('Characters', required: true),
        const SizedBox(height: 8),
        NotificationListener<ScrollNotification>(
          onNotification: (_) => true,
          child: M3EDropdownMenu<int>.future(
            future: _loadItems,
            controller: _dropdown,
            singleSelect: false,
            searchEnabled: true,
            showChipAnimation: true,
            maxSelections: 0,
            enabled: widget.enabled,
            containerRadius: 28,
            haptic: M3EHapticFeedback.light,
            fieldStyle: const M3EDropdownFieldStyle(
              hintText: 'Choose characters',
              showClearIcon: true,
              padding: EdgeInsets.all(14),
            ),
            dropdownStyle: M3EDropdownStyle(
              elevation: 4,
              maxHeight: 320,
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
              labelStyle: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colors.onSecondaryContainer),
              borderRadius: BorderRadius.circular(20),
              spacing: 6,
              runSpacing: 6,
              wrap: true,
              maxDisplayCount: 4,
              padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
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
            ),
            emptyBuilder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _catalog.error != null
                    ? "Couldn't load characters."
                    : 'No matching characters.',
              ),
            ),
            closeOnBackButton: false,
            onSelectionChanged: (items) {
              if (_syncing) return;
              widget.onChanged([for (final item in items) item.value]);
            },
          ),
        ),
        if (_catalog.error != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: M3EButton(
              onPressed: _catalog.retry,
              style: M3EButtonStyle.text,
              size: M3EButtonSize.sm,
              shape: M3EButtonShape.round,
              child: const Text('Retry characters'),
            ),
          ),
        ],
      ],
    );
  }
}
