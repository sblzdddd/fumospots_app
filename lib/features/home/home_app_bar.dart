import 'package:flutter/material.dart';
import 'package:progressive_blur/progressive_blur.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key, required this.title, required this.child});

  static const toolbarHeight = 48.0;

  final String title;
  final Widget child;

  static double headerHeightOf(BuildContext context) {
    return MediaQuery.paddingOf(context).top + toolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topInset = MediaQuery.paddingOf(context).top;
        final headerHeight = topInset + toolbarHeight;
        final fadeStop = (headerHeight / constraints.maxHeight).clamp(
          0.0,
          0.2,
        );
        final surface = Theme.of(context).colorScheme.surface;

        return Stack(
          children: [
            Positioned.fill(
              child: ProgressiveBlurWidget(
                sigma: 32.0,
                tintColor: surface.withValues(alpha: 0.8),
                linearGradientBlur: LinearGradientBlur(
                  values: const [1, 0],
                  stops: [0, fadeStop],
                  start: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                child: child,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Padding(
                padding: EdgeInsets.only(top: topInset, left: 16, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (_) {},
                      clipBehavior: Clip.antiAlias,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline),
                              SizedBox(width: 12),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined),
                              SizedBox(width: 12),
                              Text('Settings'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
