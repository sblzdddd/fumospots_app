import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

class PostFeedSkeletonCard extends StatelessWidget {
  const PostFeedSkeletonCard({super.key, required this.aspect});

  final double aspect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = colors.surfaceContainerHighest;

    return M3ESegmentedItem(
      index: 0,
      position: M3ESegmentedItemPosition.single,
      outerRadius: 16,
      innerRadius: 16,
      gap: 0,
      color: colors.surfaceContainerHigh,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1 / aspect,
            child: ColoredBox(color: fill),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 0, 32, 0),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 80,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
