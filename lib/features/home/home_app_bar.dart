import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../settings/settings_view.dart';
import '../settings/visual_settings_controller.dart';
import 'brand_logo.dart';
import 'home_view.dart';
import 'view_settings_sheet.dart';

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
            final showGradient =
                !visual.blurEnabled ||
                (selectedIndex == 0 && homeView == HomeView.map);

            return Stack(
              children: [
                Positioned.fill(child: child),
                if (showGradient)
                  Positioned.fill(
                    child: IgnorePointer(
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
        IconButton(
          tooltip: 'View settings',
          onPressed: () => showViewSettingsSheet(
            context,
            homeView: homeView,
            onHomeViewChange: onHomeViewChange,
          ),
          icon: FaIcon(
            FontAwesomeIcons.bars,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
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
