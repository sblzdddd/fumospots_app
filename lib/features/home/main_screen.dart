import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:progressive_blur/progressive_blur.dart';

import '../map/spot_map_view.dart';
import '../post/post_detail_sheet.dart';
import '../post/post_feed_view.dart';
import '../settings/visual_settings_controller.dart';
import '../user/user_view.dart';
import 'home_app_bar.dart';
import 'home_bottom_navigation.dart';
import 'home_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final VisualSettingsController _visual =
      GetIt.instance<VisualSettingsController>();
  int _selectedIndex = 0;
  HomeView _homeView = HomeView.waterfall;
  int? _selectedPostId;
  final GlobalKey _feedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _visual.addListener(_onVisualChanged);
  }

  @override
  void dispose() {
    _visual.removeListener(_onVisualChanged);
    super.dispose();
  }

  void _onVisualChanged() {
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

  Widget _blurBehindHeader(BuildContext context, Widget child) {
    if (!_visual.blurEnabled) {
      return child;
    }
    final headerHeight = HomeAppBar.headerHeightOf(context);
    final height = MediaQuery.sizeOf(context).height;
    final fadeStop = height <= 0
        ? 0.0
        : (headerHeight / height).clamp(0.0, 0.2);
    final surface = Theme.of(context).colorScheme.surface;
    return ProgressiveBlurWidget(
      sigma: 32.0,
      tintColor: surface.withValues(alpha: 0.8),
      linearGradientBlur: LinearGradientBlur(
        values: const [1, 0],
        stops: [0, fadeStop],
        start: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = HomeAppBar.headerHeightOf(context);
    final nav = HomeBottomNavigation(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
    );

    return Scaffold(
      extendBody: true,
      body: HomeAppBar(
        selectedIndex: _selectedIndex,
        homeView: _homeView,
        onHomeViewChange: (view) => setState(() => _homeView = view),
        child: _selectedIndex == 0
            ? IndexedStack(
                index: _homeView == HomeView.waterfall ? 0 : 1,
                children: [
                  _blurBehindHeader(
                    context,
                    PostFeedView(
                      key: _feedKey,
                      contentInsetTop: headerHeight,
                      onOpenPost: _openPost,
                    ),
                  ),
                  if (_homeView == HomeView.map)
                    SpotMapView(
                      contentInsetTop: headerHeight,
                      selectedPostId: _selectedPostId,
                      onOpenPost: _openPost,
                    )
                  else
                    const SizedBox.expand(),
                ],
              )
            : _blurBehindHeader(
                context,
                UserView(contentInsetTop: headerHeight),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _visual.blurEnabled
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: nav,
              ),
            )
          : nav,
    );
  }
}
