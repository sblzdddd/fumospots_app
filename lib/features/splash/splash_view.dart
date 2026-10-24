import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n/i18n.dart';
import '../home/brand_logo.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FumospotsBrandLogo(height: 72),
            const SizedBox(height: 32),
            M3ELoadingIndicator(
              color: colors.primary,
              semanticsLabel: context.t(S.loadingApp),
              constraints: const BoxConstraints.tightFor(
                width: 38,
                height: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
