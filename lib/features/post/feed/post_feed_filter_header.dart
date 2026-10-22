import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../../character/filter/character_filter_bar.dart';

const _filterHideMotion = CupertinoMotion.snappy(
  duration: Duration(milliseconds: 460),
  extraBounce: 0.03,
);

const _filterPinDuration = Duration(milliseconds: 240);
const _filterPinCurve = Curves.easeOutCubic;

class PostFeedFilterHeader extends StatelessWidget {
  const PostFeedFilterHeader({
    super.key,
    this.visible = true,
  });

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: _filterPinDuration,
        curve: _filterPinCurve,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: CharacterFilterBar(),
        ),
      ),
    );
  }
}

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
    final barVisible = BottomBarScope.maybeOf(context)?.isVisible;

    return Positioned(
      top: topInset + 8,
      left: 16,
      right: 16,
      child: barVisible == null
          ? _FilterHideSlide(shown: visible)
          : ValueListenableBuilder<bool>(
              valueListenable: barVisible,
              builder: (context, navVisible, _) {
                return _FilterHideSlide(shown: visible && navVisible);
              },
            ),
    );
  }
}

class _FilterHideSlide extends StatelessWidget {
  const _FilterHideSlide({required this.shown});

  final bool shown;

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      value: shown ? 1.0 : 0.0,
      motion: _filterHideMotion,
      builder: (context, t, child) {
        // Clamp for opacity — spring overshoot must not push alpha outside 0–1.
        final progress = t.clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: progress < 0.05,
          child: ExcludeSemantics(
            excluding: progress < 0.05,
            child: Opacity(
              opacity: progress,
              child: FractionalTranslation(
                translation: Offset(0, -(1 - t)),
                child: child,
              ),
            ),
          ),
        );
      },
      child: const CharacterFilterBar(),
    );
  }
}
