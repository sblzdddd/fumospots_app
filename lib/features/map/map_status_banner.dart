import 'package:material_ui/material_ui.dart';

import '../../core/i18n/i18n.dart';

class MapStatusBanner extends StatelessWidget {
  const MapStatusBanner({
    super.key,
    required this.loading,
    required this.empty,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final bool empty;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (empty) {
      return Text(
        context.t(S.noSpotsToShow),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (error == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.t(error!), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.t(S.retry)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
