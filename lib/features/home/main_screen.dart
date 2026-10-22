import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../map/spot_map_view.dart';
import '../post/post_detail_sheet.dart';
import '../post/post_feed_view.dart';
import '../settings/settings_view.dart';
import '../settings/visual_settings_controller.dart';
import '../user/user_view.dart';
import 'bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final VisualSettingsController _visual =
      GetIt.instance<VisualSettingsController>();
  int _selectedIndex = 0;
  int? _selectedPostId;
  bool _mapVisited = false;
  final GlobalKey _feedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _visual.addListener(_onChanged);
  }

  @override
  void dispose() {
    _visual.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openPost(int id) async {
    setState(() => _selectedPostId = id);
    await showPostDetailSheet(context, id);
    if (mounted) {
      setState(() => _selectedPostId = null);
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsView()),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _mapVisited = true;
      }
    });
  }

  void _onAddPressed() {
    // Placeholder for create-spot flow.
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final cs = Theme.of(context).colorScheme;
    final onProfile = _selectedIndex == 2;

    return Scaffold(
      appBar: onProfile
          ? AppBar(
              title: const Text('Profile'),
              actions: [
                IconButton(
                  tooltip: 'Settings',
                  onPressed: _openSettings,
                  icon: const FaIcon(FontAwesomeIcons.gear, size: 18),
                ),
              ],
            )
          : null,
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(
          maxWidth: 400,
          offset: 24,
          borderRadius: BorderRadius.all(Radius.circular(32)),
          clip: Clip.none,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
          duration: Duration(milliseconds: 460),
          extraBounce: 0.03,
        ),
        scrollBehavior: const BottomBarScrollBehavior(
          hideOnScroll: true,
          showAtStart: true,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          iconDecoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
          ),
          iconWidth: 40,
          iconHeight: 40,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            PostFeedView(
              key: _feedKey,
              contentInsetTop: topInset,
              onOpenPost: _openPost,
            ),
            if (_mapVisited)
              SpotMapView(
                contentInsetTop: topInset,
                selectedPostId: _selectedPostId,
                onOpenPost: _openPost,
              )
            else
              const SizedBox.expand(),
            const UserView(),
          ],
        ),
        child: FloatingBottomDock(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          onAddPressed: _onAddPressed,
          blurEnabled: _visual.blurEnabled,
        ),
      ),
    );
  }
}
