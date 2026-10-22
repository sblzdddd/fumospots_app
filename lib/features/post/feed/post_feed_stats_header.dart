import 'package:material_ui/material_ui.dart';

import '../../home/brand_logo.dart';
import '../post_format.dart';

class PostFeedStatsHeader extends StatelessWidget {
  const PostFeedStatsHeader({
    super.key,
    required this.topInset,
    required this.loading,
    required this.failed,
    required this.postCount,
    required this.contributorCount,
  });

  final double topInset;
  final bool loading;
  final bool failed;
  final int? postCount;
  final int? contributorCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, topInset + 20, 0, 4),
      child: Column(
        children: [
          const FumospotsBrandLogo(height: 68),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Posts',
                  value: postCount,
                  loading: loading,
                  failed: failed,
                  skeletonWidth: 88,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Contributors',
                  value: contributorCount,
                  loading: loading,
                  failed: failed,
                  skeletonWidth: 72,
                ),
              ),
            ],
          ),
          if (failed) ...[
            const SizedBox(height: 10),
            Text(
              "Couldn't load stats.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.loading,
    required this.failed,
    required this.skeletonWidth,
  });

  final String label;
  final int? value;
  final bool loading;
  final bool failed;
  final double skeletonWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shown = loading
        ? null
        : failed || value == null
        ? '--'
        : formatCount(value!);

    return Semantics(
      label: shown == null ? label : '$shown $label',
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Center(
                child: shown == null
                    ? Container(
                        width: skeletonWidth,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          shown,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 40,
                                height: 0.92,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
