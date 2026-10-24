import 'dart:ui';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

/// Floating dock child for [BottomBar]: Posts, Map, Profile, then Add.
class FloatingBottomDock extends StatelessWidget {
  const FloatingBottomDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
    this.blurEnabled = true,
    this.showMap = true,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  final bool blurEnabled;

  final bool showMap;

  static const _gap = 8.0;
  static const _radius = BorderRadius.all(Radius.circular(32));
  static const _blurSigma = 8.0;
  static const _activeFlex = 4;
  static const _inactiveFlex = 2;
  static const _duration = Duration(milliseconds: 320);
  static const _curve = Curves.easeOutCubic;
  static final _fillDecoration = M3EButtonDecoration.styleFrom(
    minimumSize: const Size(double.infinity, 40),
  );

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final dock = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final profileIndex = showMap ? 2 : 1;
          final slotCount = showMap ? 4 : 3;
          final totalFlex = _activeFlex + _inactiveFlex * (slotCount - 1);
          final available = constraints.maxWidth - _gap * (slotCount - 1);

          double widthFor({required bool active}) {
            final flex = active ? _activeFlex : _inactiveFlex;
            return available * flex / totalFlex;
          }

          final slots = <Widget>[
            _navSlot(
              width: widthFor(active: selectedIndex == 0),
              index: 0,
              tooltip: 'Posts',
              icon: FontAwesomeIcons.tableCellsLarge,
              selectedIcon: FontAwesomeIcons.tableCellsLarge,
              label: 'Posts',
            ),
            if (showMap)
              _navSlot(
                width: widthFor(active: selectedIndex == 1),
                index: 1,
                tooltip: 'Map',
                icon: FontAwesomeIcons.map,
                selectedIcon: FontAwesomeIcons.solidMap,
              ),
            _navSlot(
              width: widthFor(active: selectedIndex == profileIndex),
              index: profileIndex,
              tooltip: 'Profile',
              icon: FontAwesomeIcons.user,
              selectedIcon: FontAwesomeIcons.solidUser,
            ),
            SizedBox(
              width: widthFor(active: false),
              child: M3EButton(
                onPressed: onAddPressed,
                style: M3EButtonStyle.filled,
                shape: M3EButtonShape.round,
                size: M3EButtonSize.sm,
                decoration: _fillDecoration,
                tooltip: 'Add',
                semanticLabel: 'Add',
                child: const FaIcon(FontAwesomeIcons.plus, size: 18),
              ),
            ),
          ];

          return Row(
            children: [
              for (var i = 0; i < slots.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                slots[i],
              ],
            ],
          );
        },
      ),
    );

    final filled = ColoredBox(
      color: surface.withValues(alpha: blurEnabled ? 0.75 : 1),
      child: dock,
    );
    if (!blurEnabled) {
      return ClipRRect(borderRadius: _radius, child: filled);
    }
    return ClipRRect(
      borderRadius: _radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: filled,
      ),
    );
  }

  Widget _navSlot({
    required double width,
    required int index,
    required String tooltip,
    required FaIconData icon,
    required FaIconData selectedIcon,
    String? label,
  }) {
    final selected = selectedIndex == index;
    final iconData = selected ? selectedIcon : icon;
    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      width: width,
      child: M3EButton(
        onPressed: () => onDestinationSelected(index),
        style: selected ? M3EButtonStyle.tonal : M3EButtonStyle.text,
        shape: M3EButtonShape.round,
        size: M3EButtonSize.sm,
        decoration: _fillDecoration,
        tooltip: tooltip,
        semanticLabel: tooltip,
        child: selected && label != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(iconData, size: 18),
                  const SizedBox(width: 8),
                  Text(label, maxLines: 1, softWrap: false),
                ],
              )
            : FaIcon(iconData, size: 18),
      ),
    );
  }
}
