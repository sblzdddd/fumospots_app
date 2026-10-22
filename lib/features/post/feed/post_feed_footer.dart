import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'post_feed_skeleton_card.dart';

class PostFeedFooter extends StatelessWidget {
  const PostFeedFooter({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            M3EButton(
              onPressed: onRetry,
              style: M3EButtonStyle.text,
              shape: M3EButtonShape.round,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!loading) {
      return const SizedBox(height: 8);
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        children: [
          Expanded(child: PostFeedSkeletonCard(aspect: 1)),
          SizedBox(width: 8),
          Expanded(child: PostFeedSkeletonCard(aspect: 1.25)),
        ],
      ),
    );
  }
}
