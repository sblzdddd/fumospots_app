import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:progressive_blur/progressive_blur.dart';

import '../post/post_feed_controller.dart';
import '../post/post_model.dart';
import '../settings/settings_view.dart';
import '../settings/visual_settings_controller.dart';
import 'brand_logo.dart';
import 'home_view.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.homeView,
    required this.onHomeViewChange,
  });

  static const toolbarHeight = 58.0;

  final Widget child;
  final int selectedIndex;
  final HomeView homeView;
  final ValueChanged<HomeView> onHomeViewChange;

  static double headerHeightOf(BuildContext context) {
    return MediaQuery.paddingOf(context).top + toolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    final visual = GetIt.instance<VisualSettingsController>();

    return ListenableBuilder(
      listenable: visual,
      builder: (context, _) {
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
                  child: visual.blurEnabled
                      ? ProgressiveBlurWidget(
                          sigma: 32.0,
                          tintColor: surface.withValues(alpha: 0.8),
                          linearGradientBlur: LinearGradientBlur(
                            values: const [1, 0],
                            stops: [0, fadeStop],
                            start: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          child: child,
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            child,
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      surface.withValues(alpha: 0.92),
                                      surface.withValues(alpha: 0.0),
                                    ],
                                    stops: [0, fadeStop.clamp(0.05, 0.25)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: headerHeight,
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset, left: 8, right: 4),
                    child: selectedIndex == 0
                        ? _HomeToolbar(
                            homeView: homeView,
                            onHomeViewChange: onHomeViewChange,
                          )
                        : const _ProfileToolbar(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HomeToolbar extends StatelessWidget {
  const _HomeToolbar({
    required this.homeView,
    required this.onHomeViewChange,
  });

  final HomeView homeView;
  final ValueChanged<HomeView> onHomeViewChange;

  @override
  Widget build(BuildContext context) {
    final feed = GetIt.instance<PostFeedController>();

    return ListenableBuilder(
      listenable: feed,
      builder: (context, _) {
        return Row(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FumospotsBrandLogo(height: 40),
                ),
              ),
            ),
            PopupMenuButton<_HomeMenuAction>(
              icon: const FaIcon(FontAwesomeIcons.bars, size: 20),
              clipBehavior: Clip.antiAlias,
              onSelected: (action) {
                switch (action) {
                  case _HomeMenuAction.newest:
                    feed.load(sort: PostSortOrder.desc);
                  case _HomeMenuAction.oldest:
                    feed.load(sort: PostSortOrder.asc);
                  case _HomeMenuAction.waterfall:
                    onHomeViewChange(HomeView.waterfall);
                  case _HomeMenuAction.map:
                    onHomeViewChange(HomeView.map);
                }
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 2,
                    bottom: 1,
                  ),
                  value: _HomeMenuAction.newest,
                  checked: feed.sortOrder == PostSortOrder.desc,
                  child: const Text('Newest'),
                ),
                CheckedPopupMenuItem(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 1,
                    bottom: 0,
                  ),
                  value: _HomeMenuAction.oldest,
                  checked: feed.sortOrder == PostSortOrder.asc,
                  child: const Text('Oldest'),
                ),
                const PopupMenuDivider(),
                CheckedPopupMenuItem(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 0,
                    bottom: 1,
                  ),
                  value: _HomeMenuAction.waterfall,
                  checked: homeView == HomeView.waterfall,
                  child: const Text('Waterfall'),
                ),
                CheckedPopupMenuItem(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 1,
                    bottom: 2,
                  ),
                  value: _HomeMenuAction.map,
                  checked: homeView == HomeView.map,
                  child: const Text('Map'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProfileToolbar extends StatelessWidget {
  const _ProfileToolbar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 8),
            child: FumospotsBrandLogo(height: 28),
          ),
        ),
        Text('Profile', style: Theme.of(context).textTheme.titleLarge),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsView()),
              );
            },
            icon: const FaIcon(FontAwesomeIcons.gear, size: 18),
          ),
        ),
      ],
    );
  }
}

enum _HomeMenuAction { newest, oldest, waterfall, map }
