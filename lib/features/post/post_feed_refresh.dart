import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

Widget wrapFeedRefresh({
  required double contentInsetTop,
  required M3EPullToRefreshController controller,
  required Future<void> Function() onRefresh,
  required Widget child,
}) {
  return M3EPullToRefreshIndicator(
    controller: controller,
    onRefresh: onRefresh,
    edgeOffset: contentInsetTop,
    child: child,
  );
}

Widget withFeedBarBottomPadding(
  BuildContext context,
  Widget Function(double bottomPadding) builder,
) {
  final barHeight = BottomBarScope.maybeOf(context)?.barHeight;
  if (barHeight == null) {
    return builder(MediaQuery.paddingOf(context).bottom + 16);
  }
  return ValueListenableBuilder<double>(
    valueListenable: barHeight,
    builder: (context, value, _) => builder(value + 16),
  );
}
