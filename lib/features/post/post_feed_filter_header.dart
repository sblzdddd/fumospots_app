import 'package:material_ui/material_ui.dart';

import '../character/character_filter_bar.dart';

const _filterSnapDuration = Duration(milliseconds: 240);
const _filterSnapCurve = Curves.easeOutCubic;

/// In-flow filter slot. Height stays constant so pinning never shifts the grid.
class PostFeedFilterHeader extends StatelessWidget {
  const PostFeedFilterHeader({
    super.key,
    this.visible = true,
  });

  /// When false, keeps layout space but hides the bar (pinned overlay shows instead).
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: _filterSnapDuration,
        curve: _filterSnapCurve,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: CharacterFilterBar(),
        ),
      ),
    );
  }
}

/// Safe-area overlay that slides/fades in while the in-flow header is pinned.
class PostFeedFilterOverlay extends StatelessWidget {
  const PostFeedFilterOverlay({
    super.key,
    required this.topInset,
    required this.visible,
  });

  final double topInset;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topInset + 8,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, -0.35),
          duration: _filterSnapDuration,
          curve: _filterSnapCurve,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: _filterSnapDuration,
            curve: _filterSnapCurve,
            child: const CharacterFilterBar(),
          ),
        ),
      ),
    );
  }
}
