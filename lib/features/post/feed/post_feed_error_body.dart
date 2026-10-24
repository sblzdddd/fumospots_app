import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/i18n.dart';

class PostFeedErrorBody extends StatelessWidget {
  const PostFeedErrorBody({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t(message),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              M3EButton(
                onPressed: onRetry,
                style: M3EButtonStyle.filled,
                shape: M3EButtonShape.round,
                child: Text(context.t(S.retry)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
